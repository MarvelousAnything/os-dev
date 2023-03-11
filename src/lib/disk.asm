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

