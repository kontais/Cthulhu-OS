 ;
 ; The MIT License (MIT)
 ; Copyright (c) 2015 Peter Vanusanik <admin@en-circle.com>
 ;
 ; Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 ;
 ; The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 ;
 ; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ;
 ; entry.s
 ;  Created on: Dec 22, 2015
 ;      Author: Peter Vanusanik
 ;  Contents: base protected mode entry for kernel
 ;
[BITS 32]

; Declare constants used for creating a multiboot header.
MBALIGN     equ  1<<0                   ; align loaded modules on page boundaries
MEMINFO     equ  1<<1                   ; provide memory map
FLAGS       equ  MBALIGN | MEMINFO      ; this is the Multiboot 'flag' field
MAGIC       equ  0x1BADB002             ; 'magic number' lets bootloader find the header
CHECKSUM    equ -(MAGIC + FLAGS)        ; checksum of above, to prove we are multiboot

section .mboot
align 16
magic_header:
	dd MAGIC
	dd FLAGS
	dd CHECKSUM

section .init
GDT64:                           ; Global Descriptor Table (64-bit).
    .Null: equ $ - GDT64         ; The null descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 0                         ; Access.
    db 0                         ; Granularity.
    db 0                         ; Base (high).
    .Code: equ $ - GDT64         ; The code descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10011010b                 ; Access (exec/read).
    db 00100000b                 ; Granularity.
    db 0                         ; Base (high).
    .Data: equ $ - GDT64         ; The data descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10010010b                 ; Access (read/write).
    db 00000000b                 ; Granularity.
    db 0                         ; Base (high).
    .Pointer:                    ; The GDT-pointer.
    dw $ - GDT64 - 1             ; Limit.
    dq GDT64                     ; Base.

[GLOBAL _start]
_start:
	jmp piko_loader
piko_loader:
	push ebx
	push ebp
query_cpuid:
	pushfd               ; Store the FLAGS-register.
    pop eax              ; Restore the A-register.
    mov ecx, eax         ; Set the C-register to the A-register.
    xor eax, 1 << 21     ; Flip the ID-bit, which is bit 21.
    push eax             ; Store the A-register.
    popfd                ; Restore the FLAGS-register.
    pushfd               ; Store the FLAGS-register.
    pop eax              ; Restore the A-register.
    push ecx             ; Store the C-register.
    popfd                ; Restore the FLAGS-register.
    xor eax, ecx         ; Do a XOR-operation on the A-register and the C-register.
    jz nocpuid           ; The zero flag is set, no CPUID.
	mov eax, 0x80000000  ; Set the A-register to 0x80000000.
    cpuid                ; CPU identification.
    cmp eax, 0x80000001  ; Compare the A-register with 0x80000001.
    jb nolongmode
	mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the D-register.
    jz nolongmode
    mov eax, 0
    jmp test_cpuid
nocpuid:
	mov eax, -1
	jmp test_cpuid
nolongmode:
	mov eax, 1
test_cpuid:
	mov ecx, eax
	jecxz continue
	jmp loop
continue:
	pop ebp
	pop ebx
    jmp after_pages_set
    ALIGN 0x1000
_gpInitial_PML4:   ; Page Map Level 4
    dq   _gpInitial_PDP + 3   ; Identity Map Low 4Mb
    times 509 dq 0
    dq   _gpInitial_PML4 + 3  ; recursive mapping "trick"
    dq   _gpInitial_PDP + 3   ; Also Map to 0xFFFF8000 00000000

_gpInitial_PDP:      ; Page Directory Pointer Table
	dq _gpInitial_PD + 3
	times 509 dq 0
	dq _gpInitial_PD + 3
	dq 0

_gpInitial_PD:      ; Page Directory
    dq _gpInitial_PT1 + 3
    dq _gpInitial_PT2 + 3
    times 510 dq 0

_gpInitial_PT1:      ; Page Table 1
    %assign i 0
    %rep 512
    dq   i*4096+3
    %assign i i+1
    %endrep

_gpInitial_PT2:      ; Page Table 2
    %assign i 512
    %rep 512
    dq   i*4096+3
    %assign i i+1
    %endrep
after_pages_set:
	mov edi, _gpInitial_PML4
	mov cr3, edi				 ; Set control register 3 to the destination index.
    mov eax, cr4                 ; Set the A-register to control register 4.
    or eax, 1 << 5               ; Set the PAE-bit, which is the 6th bit (bit 5).
    mov cr4, eax                 ; Set control register 4 to the A-register.

    mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, which is the EFER MSR.
    rdmsr                        ; Read from the model-specific register.
    or eax, 1 << 8               ; Set the LM-bit which is the 9th bit (bit 8).
    wrmsr                        ; Write to the model-specific register.

    mov eax, cr0                 ; Set the A-register to control register 0.
    or eax, 1 << 31 | 1 << 0     ; Set the PG-bit, which is the 31nd bit, and the PM-bit, which is the 0th bit.
    mov cr0, eax                 ; Set control register 0 to the A-register.

    lgdt [GDT64.Pointer]         ; Load the 64-bit global descriptor table.
    extern Realm64
    jmp GDT64.Code:Trampoline    ; Set the code segment and enter 64-bit long mode.
[BITS 32]
loop:
	jmp loop
[BITS 64]
Trampoline:
 	mov rax, Realm64
    jmp rax
