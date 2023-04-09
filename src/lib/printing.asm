;
; Defines utilities for VGA text mode
;

%define ENDL 0x0A, 0x0D

;
; Puts a string to the screen
; Parameters:
;   si - string to print
;   ax - color
;
puts:
    push si
    push ax
    push bx

    .loop:
        lodsb
        or al, al
        jz .done

        mov ah, 0Eh
        mov bh, 0           ; set page number to 0
        int 10h

        jmp .loop

    .done:
        pop bx
        pop ax
        pop si
        ret