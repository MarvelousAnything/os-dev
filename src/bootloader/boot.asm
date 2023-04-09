[org 0x7C00]
[bits 16]

global boot

section .text
jmp short boot
nop

%include "src/bootloader/fat12.asm"

boot:
    ; setup data segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    ; setup stack
    mov ss, ax
    mov sp, 0x7C00

    push es
    push word .setup
    retf

 .setup:
    ; read something from the floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov si, msg_loading
    call puts

    ; read drive parameters
    push es
    mov ah, 0x08
    int 0x13
    jc floppy_error
    pop es

    and cl, 0x3F
    xor ch, ch
    ; sector count
    mov [bdb_sectors_per_track], cx

    inc dh
    ; head count
    mov [bdb_heads], dh

    ; read FAT root directory
    mov ax, [bdb_sectors_per_track]         ; LBA of root dir = reserved + fats * sectors_per_fat
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                                  ; ax = sectors_per_fat * fat_count
    add ax, [bdb_reserved_sectors]          ; ax = reserved + sectors_per_fat * fat_count
    push ax

    ; compute root dir size = (32 * root_dir_entries) / bytes_per_sector
    mov ax, [bdb_sectors_per_fat]
    shl ax, 5
    xor dx, dx
    div word [bdb_bytes_per_sector]
    test dx, dx
    jz .root_dir_size_ok
    inc ax

 .root_dir_size_ok:
    mov cl, al                      ; cl = root_dir_size
    pop ax                          ; ax = LBA of root dir
    mov dl, [ebr_drive_number]      ; dl = drive number
    mov bx, buffer                  ; es:bx = buffer
    call disk_read

    ; search for kernel.bin
    ; clear bx to count entries
    xor bx, bx
    ; di will count the current entry
    ; since the name is the first entry, di will also point to the file name field
    mov di, buffer

 ;
 ; search for kernel.bin
 ;
 .search_kernel:
    mov si, file_kernel
    mov cx, 11
    push di
    repe cmpsb                     ; compare 11 bytes. repeat until cx == 0
    pop di
    je .kernel_found

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .search_kernel
    jmp kernel_not_found

 .kernel_found:
    ; save first cluster value
    ; di should be the address to the entry
    mov ax, [di + 26]            ; ax = lower first cluster
    mov [kernel_cluster], ax

    ; read the FAT
    mov ax, [bdb_reserved_sectors]          ; LBA of FAT = reserved
    mov bx, buffer                          ; es:bx = buffer
    mov cl, [bdb_sectors_per_fat]           ; cl = sectors_per_fat
    mov dl, [ebr_drive_number]              ; dl = drive number
    call disk_read

    ; read kernel.bin and process FAT chain
    mov bx, KERNEL_LOAD_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOAD_OFFSET

 .load_kernel_loop:
    ; read the cluster
    ; first_cluster = (kernel_cluster - 2) * bdb_sectors_per_cluster + root_dir_end
    mov ax, [kernel_cluster]            ; ax = kernel_cluster
    add ax, 31                          ; ax = kernel_cluster_lba + num_sectors = root_dir_end

    ; reads 1 sector from the drive to KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]          ; overflows if kernel.bin is larger than 64Ki

    ; compute location of the next cluster
    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even

 .odd:
    shr ax, 4
    jmp .next_cluster_after
 .even:
    and ax, 0x0FFF

 .next_cluster_after:
    cmp ax, 0x0FF8
    jae .read_finish

    mov [kernel_cluster], ax
    jmp .load_kernel_loop

 .read_finish:
    ; jump to kernel
    mov dl, [ebr_drive_number]
    mov ax, KERNEL_LOAD_SEGMENT
    mov ds, ax
    mov es, ax

    jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

    jmp wait_key_and_reboot

    cli
    hlt

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot
    hlt

kernel_not_found:
    mov si, msg_kernel_not_found
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

%include "src/lib/printing.asm"
%include "src/lib/disk.asm"

msg_loading: db 'Loading...', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0
msg_kernel_not_found: db 'Kernel not found!', ENDL, 0
file_kernel: db 'KERNEL  BIN'
kernel_cluster: dw 0

KERNEL_LOAD_SEGMENT equ 0x2000
KERNEL_LOAD_OFFSET equ 0

times 510-($-$$) db 0
dw 0AA55h

buffer:
