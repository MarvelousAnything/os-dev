org 0x7C00
bits 16

%define ENDL 0x0A, 0x0D

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
bdb_heads: dw 2
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

main:
    ; init the stack pointer
    mov ax, 0
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 7C00h

    ; read something from the floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                                       ; LBA=1, second sector
    mov cl, 1                                       ; read 1 sector
    mov bx, 7E00h
    call disk_read

    mov si, msg_hello
    call puts

    hlt

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot
    hlt

wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

.halt:
    cli
    hlt

;
; Converts an LBA address to a CHS address
; Parameters:
;   - ax = LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder number
;   - dh: head number
;

lba_to_chs:
    push ax
    push dx

    xor dx, dx                                  ; clear dx
    div word [bdb_sectors_per_track]            ; ax = LBA / sectors per track
                                                ; dx = LBA % sectors per track

    inc dx                                      ; dx = (LBA % sectors per track) + 1 = sector number
    mov cx, dx                                  ; cx = sector number

    xor dx, dx                                  ; clear dx
    div word [bdb_heads]                        ; ax = (LBA / sectors per track) / heads = cylinder number
                                                ; dx = (LBA / sectors per track) % heads = head number

    mov dh, dl                                  ; dh = head number
    mov ch, al                                  ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                                   ; cl = sector number (bits 0-5) | cylinder (bits 6-15)

    pop ax
    mov dl, al                                  ; restore dl
    pop ax
    ret

;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx                                     ; save cl
    call lba_to_chs
    pop ax                                      ; AL = number of sectors  to read

    mov ah, 02h
    mov di, 3                                   ; retry count

.retry:
    pusha                                       ; save all registers, we don't know what bios modifies
    stc                                         ; set carry flag. some BIOS'es don't set it
    int 13h                                     ; carry flag cleared = success
    jnc .done                                   ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;
; Resets disk controller
; Parameters:
;   - dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg_hello: db 'Hello world!', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
