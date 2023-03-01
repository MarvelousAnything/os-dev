%define ENDL 0x0D, 0x0A

start:
    jmp main


;
; Prints a string to the screen.
; Params:
;   - ds:si points to string
;
puts:
    ; save registers we will modify
    push si
    push ax

.loop:
    lodsb           ; loads next character in al
    or al, al
    jz .done

    mov ah, 0x0E
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret


main:
    ; setup data segments
    mov ax, 0           ; cannot write to ds/es directly
    mov ds, ax
    mov es, ax

    ; setup the stack
    mov ss, ax
    mov sp, 0x7C00      ; stack grows down. therefore, this is the start of the os.

    ; print message
    mov si, msg_hello
    call puts
    
    hlt

.halt:
    jmp .halt



msg_hello: db 'Hello world!', ENDL, 0