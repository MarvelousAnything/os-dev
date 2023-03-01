org 0x7C00
bits 16

;
; FAT12 header
;

jmp short start
nop

bdb_oem: db 'MSWIN4.1'   ; 8 bytes
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 1
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0E0h
bdb_total_sectors: dw 2880
bdb_media_descriptor_type: db 0F0h
bdb_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_header: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sector_count: dd 0

; extended boot record
ebr_drive_number: db 0
                  db 0
ebr_signature:    db 29h
ebr_volume_id:    db 12h, 34h, 56h, 78h
ebr_volume_label: db 'BSOS       '
ebr_system_id:    db 'FAT12   '

start:
    jmp main

main:
    ; set video mode to 320x200 256-color graphics mode
    mov ax, 0013h
    int 10h

    ; init the stack pointer
    mov ax, 7C00h
    mov ss, ax
    mov sp, 0FFFFh

    mov ah, 0Ch
    mov al, 0000b
    mov bh, 0
    mov cx, 30
    mov dx, 100

    mov ax, 0       ; set color to red (index 4)
    mov dx, 10      ; set y coordinate to 100
    mov cx, 10      ; set x coordinate to 200
    call draw_pixel ; call draw_pixel subroutine

    ; wait for a key press before exiting
    mov ah, 00h
    int 16h

    mov ah, 4Ch
    int 21h

video_segment:
    dw 0A000h

; draw a pixel at (x, y) with color c
draw_pixel:
    push bp
    mov bp, sp

    ; save registers
    push ax
    push cx
    push dx

    ; set pixel color
    mov ah, 0Ch
    mov al, byte [bp+4]  ; load color value from stack
    mov bh, 0
    mov dx, word [bp+6]  ; load y coordinate from stack
    mov cx, word [bp+8]  ; load x coordinate from stack

    ; calculate offset address in video memory buffer
    mov bx, dx
    shl bx, 8
    add bx, cx
    shl bx, 1

    ; write pixel to video memory
    mov di, bx
    mov es, [cs:video_segment]
    mov byte [es:di], al

    ; restore registers
    pop dx
    pop cx
    pop ax

    pop bp
    ret


times 510-($-$$) db 0
dw 0AA55h
