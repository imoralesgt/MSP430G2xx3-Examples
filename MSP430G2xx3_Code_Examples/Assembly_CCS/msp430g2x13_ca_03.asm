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
;   MSP430G2x13/G2x53 Demo - Comp_A, Simple 2.2V Low Battery Detect
;
;   Description: Two comparator_A reference generators 0.25*Vcc and ~ 0.55V
;   are compared for a simple battery check of 2.2V. In the subroutine
;   Batt_Check a small capacitor that must be added to P2.3 is first charged
;   to 0.25*Vcc and then compared to ~ 0.55V. If 0.25*Vcc,
;   is above ~0.55V, P1.0 is toggled, else set. Batt_Check is
;   called constantly in an endless loop - in an actual application,
;   Batt_Check should be called very infrequently to save power.
;   ACLK = n/a, MCLK = SMCLK = default DCO
;
;   There is a tolerence of the Comp_A reference generator and in the
;   device specific datasheet. In most applications, the tolerence of the
;   reference generator is more than adequate to detect Low Battery.
;
;		 MSP430G2x13/G2x53
;             -----------------
;        /|\ |              XIN|-
;         |  |                 |
;         ---|RST          XOUT|-
;            |                 |
;      +-----|P1.1         P1.0|-->LED
;      |     |                 |
;     ===.1uf|                 |
;      |     |                 |			
;      +-----|VSS
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
            .text                           ; Program Start
;------------------------------------------------------------------------------
RESET       mov.w   #0280h,SP               ; Initialize stackpointer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
            bis.b   #001h,&P1DIR            ; P1.0 output
            mov.b   #P2CA4,&CACTL2          ; P1.1 = CA1
                                            ;
Mainloop    call    #Batt_Check             ;
            jmp     Mainloop                ;
                                            ;
;-------------------------------------------------------------------------------
Batt_Check
;-------------------------------------------------------------------------------
            mov.b   #CAREF0+CAON,&CACTL1    ; 0.25*Vcc on P2.3, Comp. on
Wait        clr.w   R15                     ; Delay to R15
L1          dec.w   R15                     ;
            jnz     L1                      ; Delay over?
            mov.b   #CARSEL+CAREF1+CAREF0+CAON,&CACTL1 ; 0.55V on -, Comp. on
            bit.b   #CAOUT,&CACTL2          ;
            clr.b   &CACTL1                 ; Disable Comp_A, save power
            jnc      Batt_Low               ;
            xor.b   #001h,&P1OUT            ; P1.0 toggle
            ret                             ;
Batt_Low    bis.b   #001h,&P1OUT            ; P1.0 set
            ret

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;      
            .end
