global _start

section .text
bits 32
_start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    ; print 'OK' to screen
    mov dword [0xb8000], 0x2f4b2f4f
    hlt

error:
    mov dword[0xb8000], 0x4f524f45
    mov dword[0xb8004], 0x4f3a4f52
    mov dword[0xb8008], 0x4f204f20
    mov byte [0xb800a], al
    hlt

check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret

.no_multiboot:
    mov al, "0"
    jmp error

check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit
    ; (bit 21) in the FLAGS register. If we can flip it, CPUID is
    ; available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is
    ; supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version store in ECX (i.e flipping
    ; the ID bit back if it was ever flipped)
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal, then that means the bit
    ; wasn't flipped, and CPUID isn't supported.
    xor eax, ecx
    jz .no_cpuid
    ret

.no_cpuid:
    mov al, "1"
    jmp error

check_long_mode:
    mov eax, 0x80000000    ; Set the A-register to 0x80000000
    cpuid                  ; CPU identification
    cmp eax, 0x80000001    ; Compare the A-register with 0x80000001
    jb .no_long_mode       ; It is less, there is no long mode
    mov eax, 0x80000001    ; Set the A-register to 0x80000001
    cpuid                  ; CPU identification
    test edx, 1 << 29      ; Test if the LM-bit is set in the D-reg
    jz .no_long_mode       ; They aren't, there is no long mode
    ret

.no_long_mode:
    mov al, "a"
    jmp error

section .bss
stack_bottom:
    resb 64
stack_top:
