bits 16
org 0x7C00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Вивід повідомлення про завантаження
    mov si, bootmsg
    call print_slow

    ; ЗАВАНТАЖЕННЯ ЯДРА
    mov ah, 0x02    ; Функція читання секторів
    mov al, 5       ; Читаємо 5 секторів (про запас, щоб ядро влізло)
    mov ch, 0       ; Циліндр 0
    mov cl, 2       ; Починаємо з 2-го сектора (одразу після bootloader)
    mov dh, 0       ; Головка 0
    mov dl, 0x80    ; HDD 0 (в QEMU зазвичай 0x80 для дисків)
    mov bx, 0x1000  ; Адреса в пам'яті (ES:BX = 0000:1000)
    int 0x13

    ; Перехід до ядра
    jmp 0x0000:0x1000

; ===== PRINT WITH DELAY =====
print_slow:
.next:
    lodsb
    cmp al,0
    je .done
    mov ah,0x0E
    int 0x10
    call delay
    jmp .next
.done:
    ret

delay:
    push cx
    mov cx, 0x7FFF ; Трохи зменшив затримку для комфорту
.d:
    loop .d
    pop cx
    ret

bootmsg db 13,10,"Booting ColrsOS0.3...",13,10,0

times 510-($-$$) db 0
dw 0xAA55