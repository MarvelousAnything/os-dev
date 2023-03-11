org 0x7C00
section .text
bits 16

global start

jmp short start
nop

%include "src/bootloader/fat12.asm"

start:
    jmp main

%include "src/lib/vga.asm"

main:
    ; init the stack pointer
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; read something from the floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                                       ; LBA=1, second sector
    mov cl, 1                                       ; read 1 sector
    mov bx, 7E00h
    call disk_read

    mov si, msg_hello
    call puts

    cli
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

%include "src/lib/disk.asm"

msg_hello: db 'Hello world!', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
