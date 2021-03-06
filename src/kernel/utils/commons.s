 ;
 ; The MIT License (MIT)
 ; Copyright (c) 2015 Peter Vanusanik <admin@en-circle.com>
 ;
 ; Permission is hereby granted, free of charge, to any person obtaining a copy
 ; of this software and associated documentation files (the "Software"), to deal in
 ; the Software without restriction, including without limitation the rights to use, copy,
 ; modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
 ; to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 ;
 ; The above copyright notice and this permission notice shall be included in all copies
 ; or substantial portions of the Software.
 ;
 ; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 ; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 ; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 ; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 ; CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 ; OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ;
 ; commons.s
 ;  Created on: Dec 22, 2015
 ;      Author: Peter Vanusanik
 ;  Contents: common assembly operations
 ;

[BITS 64]

[GLOBAL kp_halt]
; Halts all cpus
;
; TODO: actually halt all cpus
;
; extern void kp_halt()
kp_halt:
    cli
    hlt
    jmp kp_halt

[GLOBAL check_cpuid_apic]
; Checks CPUID for APIC
;
; extern void* check_cpuid_apic()
check_cpuid_apic:
    mov rax, 1
    cpuid
    mov rax, rdx
    and rax, 1<<9
    ret
