org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A
%define COM1_BASE 0x3F9
%define BAUD_RATE 9600

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

    ; set pixel color to red (color index 4)
    mov ah, 0Ch
    mov al, 4

    ; set pixel coordinates (x=100, y=100)
    mov cx, 100
    mov dx, 100

    ; calculate the pixel offset in the video memory buffer
    mov bx, cx
    shl bx, 1
    shl dx, 8
    add bx, dx

    ; write pixel to video memory
    mov es, [cs:video_segment]
    mov di, bx
    stosb

    ; wait for a key press before exiting
    mov ah, 00h
    int 16h
    
    mov ah, 4Ch
    int 21h

video_segment:
    dw 0A000h

times 510-($-$$) db 0
dw 0AA55h