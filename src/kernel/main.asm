org 0x0
bits 16

start:
    mov si, msg_kernel_loaded
    call puts

.halt:
    cli
    hlt

%include "src/lib/printing.asm"
msg_kernel_loaded: db 'Kernel Loaded!', ENDL, 0
