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

    mov bl, 0x1F ; Синій фон
    call set_bg_color
    
    call animate_intro_logo 

menu_loop:
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

    ; --- ПЕРЕВІРКА КОМАНД ---
    mov si, buffer
    mov di, cmd_clear
    call strcmp
    cmp ax, 1
    je clear_cmd

    mov si, buffer
    mov di, cmd_help
    call strcmp
    cmp ax, 1
    je help_cmd

    mov si, buffer
    mov di, cmd_start
    call strcmp
    cmp ax, 1
    je start_cmd

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

; ===== ФУНКЦІЇ АНІМАЦІЇ ТА ЛОГОТИПА =====

animate_intro_logo:
    call get_cpu_name
    call get_memory_info
    call cls
    
    ; Кадр 1
    mov si, logoline1_anim1
    call print
    mov si, logoline2_anim1
    call print
    mov si, logoline3_anim1
    call print
    mov si, logoline4_anim1
    call print
    mov si, logoline5_anim1
    call print
    mov si, logoline6_anim1
    call print
    mov si, logoline7_anim1
    call print
    call small_delay
    call cls

    ; Кадр 2
    mov si, logoline1_anim2
    call print
    mov si, logoline2_anim2
    call print
    mov si, logoline3_anim2
    call print
    mov si, logoline4_anim2
    call print
    mov si, logoline5_anim2
    call print
    mov si, logoline6_anim2
    call print
    mov si, logoline7_anim2
    call print
    call small_delay
    call cls

    ; Кадр 3
    mov si, logoline1_anim3
    call print
    mov si, logoline2_anim3
    call print
    mov si, logoline3_anim3
    call print
    mov si, logoline4_anim3
    call print
    mov si, logoline5_anim3
    call print
    mov si, logoline6_anim3
    call print
    mov si, logoline7_anim3
    call print
    call small_delay
    call cls

    call draw_header
    ret

draw_header:
    mov si, logoline1
    call print
    mov si, logoline2
    call print
    
    mov si, cpu_prefix
    call print
    mov si, cpu_string
    call print
    call print_newline

    mov si, logoline4
    call print

    mov si, mem_prefix
    call print
    mov si, mem_string
    call print
    mov si, kb_suffix
    call print
    call print_newline

    mov si, time_prefix
    call print
    call get_datetime
    
    mov si, logoline7
    call print
    ret

; ===== СИСТЕМНІ ФУНКЦІЇ =====

get_cpu_name:
    mov eax, 0x80000002
    cpuid
    mov [cpu_string], eax
    mov [cpu_string+4], ebx
    mov [cpu_string+8], ecx
    mov [cpu_string+12], edx
    mov eax, 0x80000003
    cpuid
    mov [cpu_string+16], eax
    mov [cpu_string+20], ebx
    mov [cpu_string+24], ecx
    mov [cpu_string+28], edx
    mov eax, 0x80000004
    cpuid
    mov [cpu_string+32], eax
    mov [cpu_string+36], ebx
    mov [cpu_string+40], ecx
    mov [cpu_string+44], edx
    ret

get_memory_info:
    int 0x12 ;
    mov dx, ax
    mov di, mem_string
    call ax_to_decimal
    ret

get_datetime:
    mov ah, 0x04
    int 0x1A ;
    mov al, dl
    call print_bcd_byte
    mov al, '.'
    call print_char
    mov al, dh
    call print_bcd_byte
    mov al, ' '
    call print_char
    mov ah, 0x02
    int 0x1A
    mov al, ch
    call print_bcd_byte
    mov al, ':'
    call print_char
    mov al, cl
    call print_bcd_byte
    call print_newline
    ret

print_bcd_byte:
    push ax
    shr al, 4
    add al, '0'
    call print_char
    pop ax
    and al, 0x0F
    add al, '0'
    call print_char
    ret

ax_to_decimal:
    mov cx, 0
    mov bx, 10
.loop1:
    mov dx, 0
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .loop1
.loop2:
    pop dx
    add dl, '0'
    mov [di], dl
    inc di
    loop .loop2
    mov byte [di], 0
    ret

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 10h
    jmp print
.done: ret

print_char:
    mov ah, 0x0E
    int 10h
    ret

cls:
    mov ax, 0003h
    int 10h
    ret

print_newline:
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
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

small_delay:
    mov cx, 0xFFFF
.d1: loop .d1
    ret

; ===== ДАНІ (DATA) =====

logoline1  db "       ^          ColrsOS v0.5", 13, 10, 0
logoline2  db "      / \         --------------", 13, 10, 0
cpu_prefix db "     /   \        CPU: ", 0
logoline4  db "    /  _  \       GPU: VGA Controller", 13, 10, 0
mem_prefix db "   /  / \  \      RAM: ", 0
kb_suffix  db " KB", 0
time_prefix db "  /  /___\  \     SYS: ", 0
logoline7  db " /___________\    Status: SYSTEM@ROOT", 13, 10, 0

; Порожні рядки для анімації (кадр 1)
logoline1_anim1 db 13, 10, 0
logoline2_anim1 db 13, 10, 0
logoline3_anim1 db 13, 10, 0
logoline4_anim1 db 13, 10, 0
logoline5_anim1 db 13, 10, 0
logoline6_anim1 db 13, 10, 0
logoline7_anim1 db 13, 10, 0

; Тільки трикутник (кадр 2)
logoline1_anim2 db "       ^", 13, 10, 0
logoline2_anim2 db "      / \", 13, 10, 0
logoline3_anim2 db "     /   \", 13, 10, 0
logoline4_anim2 db "    /  _  \", 13, 10, 0
logoline5_anim2 db "   /  / \  \", 13, 10, 0
logoline6_anim2 db "  /  /___\  \", 13, 10, 0
logoline7_anim2 db " /___________\", 13, 10, 0

; Трикутник + Назва (кадр 3)
logoline1_anim3 db "       ^          ColrsOS v0.5", 13, 10, 0
logoline2_anim3 db "      / \         --------------", 13, 10, 0
logoline3_anim3 db "     /   \", 13, 10, 0
logoline4_anim3 db "    /  _  \", 13, 10, 0
logoline5_anim3 db "   /  / \  \", 13, 10, 0
logoline6_anim3 db "  /  /___\  \", 13, 10, 0
logoline7_anim3 db " /___________\", 13, 10, 0

prompt     db 13, 10, " [SYSTEM@ROOT]:# ", 0
unknown    db " Unknown command!", 13, 10, 0
startmsg   db " Starting system services...", 13, 10, 0
helpmsg    db " Commands: start, help, clear, echo, sysinfo, animalgame, color, exit", 13, 10, 0
echomsg    db " Enter text: ", 0
sysinfomsg db " ColrsOS v0.5 (x86 16-bit)", 13, 10, 0

animal_quest  db " Guess: It says 'Meow'?", 13, 10, "> ", 0
animal_answer db "cat", 0
animal_right  db " Correct!", 13, 10, 0
animal_wrong  db " Wrong.", 13, 10, 0
colormsg_info db " Themes: 1-Blue, 2-Green, 3-Red", 13, 10, 0

cmd_clear  db "clear", 0
cmd_start  db "start", 0
cmd_help   db "help", 0
cmd_exit   db "exit", 0
cmd_echo   db "echo", 0
cmd_info   db "sysinfo", 0
cmd_animal db "animalgame", 0
cmd_color  db "color", 0

cpu_string times 49 db 0
mem_string times 7 db 0
buffer     times 64 db 0