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

    call cls

    mov si, logo
    call print

menu_loop:
    mov si, menu
    call print

    mov di, buffer
    call read_line

    ; Перевірка команд
    mov si, buffer
    mov di, cmd_start
    call strcmp
    cmp ax,1
    je start_cmd

    mov si, buffer
    mov di, cmd_help
    call strcmp
    cmp ax,1
    je help_cmd

    mov si, buffer
    mov di, cmd_exit
    call strcmp
    cmp ax,1
    je reboot

    mov si, buffer
    mov di, cmd_echo
    call strcmp
    cmp ax,1
    je echo_cmd

    mov si, buffer
    mov di, cmd_info
    call strcmp
    cmp ax,1
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

    ; Якщо нічого не підійшло
    mov si, unknown
    call print
    jmp menu_loop

; ===== COMMANDS =====
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
    
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
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

    ; Налаштування кольорів (Фон)
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
    mov ah, 0x06       
    xor al, al         
    mov bh, bl         
    mov cx, 0x0000     
    mov dx, 0x184F
    int 10h

    ; Повертаємо курсор у початок
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h

    jmp menu_loop

reboot:
    int 19h

; ===== FUNCTIONS =====
print:
.next:
    lodsb
    cmp al,0
    je .done
    mov ah,0x0E
    int 10h
    jmp .next
.done:
    ret

cls:
    mov ax,0003h
    int 10h
    ret

read_line:
.read:
    mov ah,0
    int 16h
    cmp al,13
    je .done
    mov ah,0Eh
    int 10h
    stosb
    jmp .read
.done:
    mov al,0
    stosb
    mov ah,0Eh
    mov al,13
    int 10h
    mov al,10
    int 10h
    ret

strcmp:
.loop:
    mov al,[si]
    mov bl,[di]
    cmp al,bl
    jne .no
    cmp al,0
    je .yes
    inc si
    inc di
    jmp .loop
.yes:
    mov ax,1
    ret
.no:
    xor ax,ax
    ret

; ===== DATA =====
logo db 13,10,"=======ColrsOS Menu=======",13,10,0
menu db 13,10,"Commands: start, help, exit, echo, sysinfo animalgame and color",13,10,"> ",0
unknown db "Unknown command!",13,10,0
startmsg db "Starting system services...",13,10,0
helpmsg db "Available: start, help, exit, echo, sysinfo, color, Animalgame",13,10,0
echomsg db "Enter text: ",0
sysinfomsg db "ColrsOS v0.2 (x86 16-bit)",13,10,0

cmd_start db "start",0
cmd_help db "help",0
cmd_exit db "exit",0
cmd_echo db "echo",0
cmd_info db "sysinfo",0
cmd_animal    db "animalgame", 0
animal_quest  db "Guess the animal: It says 'Meow'?", 13, 10, "> ", 0
animal_answer db "cat", 0
animal_right  db "Correct! It is a cat!", 13, 10, 0
animal_wrong  db "Wrong! Try again.", 13, 10, 0
cmd_color       db "color", 0
colormsg_info   db "Pick color: 1-Blue, 2-Green, 3-Red", 13, 10, 0

buffer times 64 db 0