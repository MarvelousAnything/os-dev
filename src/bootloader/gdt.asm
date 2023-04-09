; ---------------------------------------------------------------------
; Global descriptor table

gdt:
    ;
    ; Null descriptor
    ;
    gdt_null:
        dq 0

    ;
    ; Kernel code segment
    ;
    gdt_code:
        dw 0x0ffff
        dw 0
        db 0
        db 10011010b
        db 11001111b
        db 0

    ;
    ; Kernel data segment
    ;
    gdt_data:
        dw 0x0ffff
        dw 0
        db 0
        db 10010010b
        db 11001111b
        db 0

    gdt_end:

    ;
    ; GDT pointer
    ;
    gdt_ptr:
        dw gdt_end - gdt_null - 1
        dq gdt_null

    ;
    ; Enter protected mode
    ;
    enter_protected_mode:
        lgdt [gdt_ptr]
        mov ax, DATA_SEG
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov ax, CODE_SEG
        push ax
        push offset protected_mode
        retf

    ;
    ; Segment selectors
    ;
    CODE_SEG equ gdt_code - gdt_null
    DATA_SEG equ gdt_data - gdt_null


