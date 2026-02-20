bits 16
org 0x1000

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9C00
    sti

    ; Початковий колір (Синій фон)
    mov bl, 0x1F
    call set_bg_color
    
    call cls
    call draw_header

menu_loop:
    ; Очищення буфера вводу
    mov di, buffer
    mov al, 0
    mov cx, 64
    rep stosb

    mov si, prompt
    call print

    mov di, buffer
    call read_line

    cmp byte [buffer], 0
    je menu_loop

    ; --- ПОРІВНЯННЯ КОМАНД ---
    mov si, buffer
    mov di, cmd_clear
    call strcmp
    cmp ax, 1
    je clear_cmd

    mov si, buffer
    mov di, cmd_start
    call strcmp
    cmp ax, 1
    je start_cmd

    mov si, buffer
    mov di, cmd_help
    call strcmp
    cmp ax, 1
    je help_cmd

    mov si, buffer
    mov di, cmd_echo
    call strcmp
    cmp ax, 1
    je echo_cmd

    mov si, buffer
    mov di, cmd_info
    call strcmp
    cmp ax, 1
    je sysinfo_cmd

    mov si, buffer
    mov di, cmd_animal
    call strcmp
    cmp ax, 1
    je animal_game

    mov si, buffer
    mov di, cmd_color
    call strcmp
    cmp ax, 1
    je color_manager

    mov si, buffer
    mov di, cmd_exit
    call strcmp
    cmp ax, 1
    je reboot

    ; Якщо команда невідома
    mov si, unknown
    call print
    jmp menu_loop

; ===== ОБРОБНИКИ КОМАНД =====

clear_cmd:
    call cls
    call draw_header
    jmp menu_loop

start_cmd:
    mov si, startmsg
    call print
    jmp menu_loop

help_cmd:
    mov si, helpmsg
    call print
    jmp menu_loop

echo_cmd:
    mov si, echomsg
    call print
    mov di, buffer
    call read_line
    mov si, buffer
    call print
    call print_newline
    jmp menu_loop

sysinfo_cmd:
    mov si, sysinfomsg
    call print
    jmp menu_loop

animal_game:
    mov si, animal_quest
    call print
    mov di, buffer
    call read_line
    mov si, buffer
    mov di, animal_answer
    call strcmp
    cmp ax, 1
    je .win
.lose:
    mov si, animal_wrong
    call print
    jmp menu_loop
.win:
    mov si, animal_right
    call print
    jmp menu_loop

color_manager:
    mov si, colormsg_info
    call print
    mov ah, 0
    int 16h
    cmp al, '1'
    je .blue
    cmp al, '2'
    je .green
    cmp al, '3'
    je .red
    jmp menu_loop
.blue:  
    mov bl, 0x1F
    jmp .apply
.green: 
    mov bl, 0x20
    jmp .apply
.red:   
    mov bl, 0x4F
.apply:
    call set_bg_color
    call cls
    call draw_header
    jmp menu_loop

reboot:
    int 19h

; ===== ФУНКЦІЇ ІНТЕРФЕЙСУ =====

get_cpu_name:
    ; Отримуємо Brand String процесора (частина 1)
    mov eax, 0x80000002
    cpuid
    mov [cpu_string], eax
    mov [cpu_string+4], ebx
    mov [cpu_string+8], ecx
    mov [cpu_string+12], edx
    ; Частина 2
    mov eax, 0x80000003
    cpuid
    mov [cpu_string+16], eax
    mov [cpu_string+20], ebx
    mov [cpu_string+24], ecx
    mov [cpu_string+28], edx
    ; Частина 3
    mov eax, 0x80000004
    cpuid
    mov [cpu_string+32], eax
    mov [cpu_string+36], ebx
    mov [cpu_string+40], ecx
    mov [cpu_string+44], edx
    ret

draw_header:
    call get_cpu_name
    mov si, logoline1
    call print
    mov si, logoline2
    call print
    mov si, logoline3
    call print
    mov si, logoline4
    call print
    
    ; Динамічний рядок з процесором
    mov si, cpu_prefix
    call print
    mov si, cpu_string
    call print
    call print_newline

    mov si, logoline6
    call print
    mov si, logoline7
    call print
    ret

set_bg_color:
    mov ah, 0x06
    xor al, al
    mov bh, bl
    mov cx, 0x0000
    mov dx, 0x184F
    int 10h
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 10h
    ret

print_newline:
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    ret

; ===== СИСТЕМНІ ФУНКЦІЇ =====

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 10h
    jmp print
.done: ret

cls:
    mov ax, 0003h
    int 10h
    ret

read_line:
    xor cx, cx
.read:
    mov ah, 0
    int 16h
    cmp al, 13
    je .done
    cmp al, 8
    je .backspace
    cmp cx, 63
    jae .read
    stosb
    inc cx
    mov ah, 0x0E
    int 10h
    jmp .read
.backspace:
    jcxz .read
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    jmp .read
.done:
    mov al, 0
    stosb
    call print_newline
    ret

strcmp:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .no
    or al, al
    jz .yes
    inc si
    inc di
    jmp .loop
.yes: 
    mov ax, 1
    ret
.no: 
    xor ax, ax
    ret

; ===== ДАНІ (DATA) =====

logoline1 db "       ^          ColrsOS v0.3", 13, 10, 0
logoline2 db "      / \         --------------", 13, 10, 0
logoline3 db "     /   \        Kernel: custom 16-bit", 13, 10, 0
logoline4 db "    /  _  \       Shell:  colshell", 13, 10, 0
cpu_prefix db "   /  / \  \      CPU:    ", 0 
logoline6 db "  /  /___\  \     Memory: 1024KB RAM", 13, 10, 0
logoline7 db " /___________\    Status: SYSTEM@ROOT", 13, 10, 0

prompt     db 13, 10, " [SYSTEM@ROOT]:# ", 0
unknown    db " Unknown command!", 13, 10, 0
startmsg   db " Starting system services...", 13, 10, 0
helpmsg    db " Available: start, help, clear, echo, sysinfo, animalgame, color, exit", 13, 10, 0
echomsg    db " Enter text: ", 0
sysinfomsg db " ColrsOS v0.3 (x86 16-bit)", 13, 10, 0

animal_quest  db " Guess the animal: It says 'Meow'?", 13, 10, "> ", 0
animal_answer db "cat", 0
animal_right  db " Correct! It is a cat!", 13, 10, 0
animal_wrong  db " Wrong! Try again.", 13, 10, 0
colormsg_info db " Pick color: 1-Blue, 2-Green, 3-Red", 13, 10, 0

cmd_clear  db "clear", 0
cmd_start  db "start", 0
cmd_help   db "help", 0
cmd_exit   db "exit", 0
cmd_echo   db "echo", 0
cmd_info   db "sysinfo", 0
cmd_animal db "animalgame", 0
cmd_color  db "color", 0

cpu_string times 49 db 0
buffer times 64 db 0