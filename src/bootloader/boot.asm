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
    ; init the stack pointer
    mov ax, 7C00h
    mov ss, ax
    mov sp, 0FFFFh

    mov ax, 13h
    int 10h

    call draw_line

    jmp $                   ; infinite loop


;
; Draw line
; Input: none
; Output: none
;
draw_line:


;
; Calculate pixel position
; Input: ax = y
;        bx = x
; Output: ax = pixel position
;
calc_pixel_pos:
    push cx
    mov cx, 320
    imul ax, cx
    add ax, bx
    pop cx
    ret

;
; Draw pixel to video memory
; Input: ax = y
;        bx = x
;        dl = color
; Output: none
;
draw_pixel:
    mov es, [cs:video_segment]
    call calc_pixel_pos
    mov di, ax
    mov [es:di], dl
    ret

video_segment: dw 0A000h



times 510-($-$$) db 0
dw 0AA55h
