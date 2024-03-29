; --COPYRIGHT--,BSD_EX
;  Copyright (c) 2012, Texas Instruments Incorporated
;  All rights reserved.
; 
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
; 
;  *  Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
; 
;  *  Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
; 
;  *  Neither the name of Texas Instruments Incorporated nor the names of
;     its contributors may be used to endorse or promote products derived
;     from this software without specific prior written permission.
; 
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; 
; ******************************************************************************
;  
;                        MSP430 CODE EXAMPLE DISCLAIMER
; 
;  MSP430 code examples are self-contained low-level programs that typically
;  demonstrate a single peripheral function or device feature in a highly
;  concise manner. For this the code may rely on the device's power-on default
;  register values and settings such as the clock configuration and care must
;  be taken when combining code from several examples to avoid potential side
;  effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
;  for an API functional library-approach to peripheral configuration.
; 
; --/COPYRIGHT--
;*******************************************************************************
;   MSP430G2x33/G2x53 Demo - ADC10, Sample A10 Temp and Convert to oC and oF
;
;   Description: A single sample is made on A10 with reference to internal
;   1.5V Vref. Software sets ADC10SC to start sample and conversion - ADC10SC
;   automatically cleared at EOC. ADC10 internal oscillator/4 times sample
;   (64x) and conversion. In Mainloop MSP430 waits in LPM0 to save power until
;   ADC10 conversion complete, ADC10_ISR will force exit from any LPMx in
;   Mainloop on reti. Result is converted to Temperature represented as
;   BCD 0000 - 0145 representing oC saved at 0200h and 0000 - 0292 representing
;   oF saved at 0202h. Temperature sensor offset and slope will vary from device
;   to device per datasheet tolerance.
;   Uncalibrated temperature measured from device to devive will vary with
;   slope and offset - please see datasheet.
;   ACLK = n/a, MCLK = SMCLK = default DCO ~1.2MHz, ADC10CLK = ADC10OSC/4
;
;                MSP430G2x33/G2x53
;             -----------------
;         /|\|              XIN|-
;          | |                 |
;          --|RST          XOUT|-
;            |                 |
;            |A10              |
;
;   D. Dang
;   Texas Instruments Inc.
;   December 2010
;   Built with Code Composer Essentials Version: 4.2.0
;*******************************************************************************
 .cdecls C,LIST,  "msp430.h"
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

;------------------------------------------------------------------------------
            .text                           ; Progam Start
;------------------------------------------------------------------------------
RESET       mov.w   #0280h,SP               ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupADC10  mov.w   #INCH_10+ADC10DIV_3,&ADC10CTL1     ; Temp Sensor ADC10CLK/4
            mov.w   #SREF_1+ADC10SHT_3+REFON+ADC10ON+ADC10IE,&ADC10CTL0 ;
            mov.w   #30,&TACCR0             ; Delay to allow Ref to settle
            bis.w   #CCIE,&TACCTL0          ; Compare-mode interrupt.
            mov.w   #TACLR+MC_1+TASSEL_2,&TACTL; up mode, SMCLK
            bis.w   #LPM0+GIE,SR            ; Enter LPM0, enable interrupts
            bic.w   #CCIE,&TACCTL0          ; Disable timer interrupt
            dint                            ;
                                            ;
Mainloop    bis.w   #ENC+ADC10SC,&ADC10CTL0 ; Start sampling/conversion
            bis.w   #CPUOFF+GIE,SR          ; LPM0, ADC10_ISR will force exit
            call    #Trans2TempC            ; Transform voltage to temperature
            call    #BIN2BCD4               ; R13 = TempC = 0000 - 0145 BCD
            mov.w   R13,&0200h              ; 0200h = temperature oC
            call    #Trans2TempF            ; Transform voltage to temperature
            call    #BIN2BCD4               ; R13 = TempF = 0000 - 0292 BCD
            mov.w   R13,&0202h              ; 0202h = temperature oF
            jmp     Mainloop                ; << breakpoint here
                                            ;
;-------------------------------------------------------------------------------
Trans2TempC;Subroutine coverts R12 = ADC10MEM/1024*423-278
;           oC = ((x/1024)*1500mV)-986mV)*1/3.55mV = x*423/1024 - 278
;           Input:  ADC10MEM  0000 - 0FFFh, R11, R12, R14, R15 working register
;           Output: R12  0000 - 091h
;-------------------------------------------------------------------------------
            mov.w   &ADC10MEM,R12           ;
            mov.w   #423,R11                ; C
            call    #MPYU                   ;
            bic.w   #00FFh,R14              ; /1024
            add.w   R15,R14                 ;
            swpb    R14                     ;
            rra.w   R14                     ;
            rra.w   R14                     ;
            mov.w   R14,R12                 ;
            sub.w   #278,R12                ; C
            ret                             ;
                                            ;
;-------------------------------------------------------------------------------
Trans2TempF;Subroutine coverts R12 = ADC10MEM/1024*761-468
;           oF = ((x/1024)*1500mV)-923mV)*1/1.97mV = x*761/1024 - 468
;           Input:  ADC10MEM  0000 - 0FFFh, R11, R12, R14, R15 working register
;           Output: R12  0000 - 0124h
;-------------------------------------------------------------------------------
            mov.w   &ADC10MEM,R12           ;
            mov.w   #761,R11                ; F
            call    #MPYU                   ;
            bic.w   #00FFh,R14              ; /1024
            add.w   R15,R14                 ;
            swpb    R14                     ;
            rra.w   R14                     ;
            rra.w   R14                     ;
            mov.w   R14,R12                 ;
            sub.w   #468,R12                ; F
            ret                             ;
                                            ;
;-------------------------------------------------------------------------------
BIN2BCD4  ; Subroutine converts binary number R12 -> Packed 4- digit BCD R13
;           Input:  R12  0000 - 0FFFh, R15 working register
;           Output: R13  0000 - 4095
;-------------------------------------------------------------------------------
            mov.w   #16,R15                 ; Loop Counter
            clr.w   R13                     ; 0 -> RESULT LSD
BIN1        rla.w   R12                     ; Binary MSB to carry
            dadd.w  R13,R13                 ; RESULT x2 LSD
            dec.w   R15                     ; Through?
            jnz     BIN1                    ; Not through
            ret                             ;
                                            ;
;-------------------------------------------------------------------------------
MPYU   ;    Unsigned Multipy R11 x R12 = R15|R14
       ;    Input:  R11, R12 -- R10 and R13 are working registers
       ;    Output: R15, R14
;-------------------------------------------------------------------------------
            clr.w   R14                     ; 0 -> LSBs result
            clr.w   R15                     ; 0 -> MSBs result
MACU        clr.w   R13                     ; MSBs multiplier
            mov.w   #1,R10                  ; bit test register
MPY2        bit.w   R10,R11                 ; test actual bit
            jz      MPY1                    ; IF 0: do nothing
            add.w   R12,R14                 ; IF 1: add multiplier to result
            addc.w  R13,R15                 ;
MPY1        rla.w   R12                     ; multiplier x 2
            rlc.w   R13                     ;
            rla.w   R10                     ; next bit to test
            jnc     MPY2                    ; if bit in carry: finished
            ret                             ; Return from subroutine
                                            ;
;-------------------------------------------------------------------------------
TA0_ISR;    ISR for TACCR0
;-------------------------------------------------------------------------------
            clr.w   &TACTL                  ; Clear Timer_A control registers
            bic.w   #LPM0,0(SP)             ; Exit LPMx, interrupts enabled
            reti                            ;
;-------------------------------------------------------------------------------
ADC10_ISR;
;-------------------------------------------------------------------------------
            bic.w   #LPM0,0(SP)             ; Exit LPM0 on reti
            reti                            ;
                                            ;
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;
            .sect   ".int05"                ; ADC10 Vector
            .short  ADC10_ISR               ;
            .sect   ".int09"                ; Timer_A0 Vector
            .short  TA0_ISR                 ;
            .end

