  TITLE EMMTSR 

 .model tiny
off_int08   equ 20h
seg_int08   equ 22h
interval_oprosa equ 9;
        .code
        org 100h
main    proc
start:  jmp m1
ncb1_command    db ?
ncb1_retcode    db ?
ncb1_lsn        db 0
ncb1_num        db 0
ncb1_buffer     dw 8000h
                dw 0b000h
ncb1_length     dw 4096
ncb1_callname   db 'LOCAL           '
ncb1_name       db '1234567890      '
ncb1_rto        db 0
ncb1_sto        db 0
ncb1_post       dd 0
ncb1_lana       db 0
ncb1_cplt       db 0ffh
ncb1_reserved   db 14 dup(?)
;
ncb2_command    db ?
ncb2_retcode    db ?
ncb2_lsn        db 0
ncb2_num        db 0
ncb2_buffer     dw 17h
                dw 40h
ncb2_length     dw 27h
ncb2_callname   db 'LOCAL           '
ncb2_name       db '1234567890      '
ncb2_rto        db 0
ncb2_sto        db 0
ncb2_post       dd 0
ncb2_lana       db 0
ncb2_cplt       db 0ffh
ncb2_reserved   db 14 dup(?)
;
int_timer       dw  0
                dw  0
timer           db  5
;
irq_0:          cli
                pushf
                call  dword ptr cs:int_timer
                push ds
                push ax
             	push es
		push bx
		mov ax,cs
                mov ds,ax
                dec byte ptr timer
                jz c1
                jmp irq_ret
;
c1:             mov byte ptr timer,interval_oprosa
;
		cmp ncb1_cplt,0ffh
		jz irq_ret
                mov es,ax
		mov ncb1_cplt,0ffh
                mov bx,offset ncb1_command
                mov ncb1_command,94h
                int 5ch
                cmp ncb2_cplt,0ffh
		jz irq_ret
		mov bx,offset ncb2_command
		mov ncb2_cplt,0ffh
                mov ncb2_command,95h
                int 5ch
;
irq_ret:        pop bx
		pop es
		pop ax
                pop ds
                iret
;
error_reset     db 0dh,0ah,'Сбой адаптеpа',7,0dh,0ah,'$'
error_addname db 0dh,0ah,'Сбой имени',7,0dh,0ah,'$'
error_listen    db  0dh,0ah,'Сбой listen',7,0dh,0ah,'$'
error_listen2   db 0dh,0ah,'Сбой listen ncb2',7,0dh,0ah,'$'

m1:             
                push ds
                push es
		push bx
                mov bx,offset ncb1_command
                mov ncb1_command,32h
                int 5ch
                and al,al
                jz reset_ok
                mov ah,9
                mov dx,offset error_reset
                int 21h
                mov ax,4c01h
                int 21h
;
reset_ok:       mov ncb1_command,30h
                int 5ch
                and al,al
                jz add_name_ok
                mov ah,9
                mov dx,offset error_addname
                int 21h
                mov ax,4c01h
                int 21h
;
add_name_ok:
                mov ncb1_cplt,0ffh
                mov ncb1_command,91h
                int 5ch
                and al,al
                jz listen_ok
                mov ah,9
                mov dx,offset error_listen
                int 21h
                mov ax,4c01h
                int 21h
;
listen_ok:      mov bx,offset ncb2_command
                mov ncb2_cplt,0ffh
                mov ncb2_command,91h
                int 5ch
                and al,al
                jz listen3_ok
                mov ah,9
                mov dx,offset error_listen2
                int 21h
                mov ax,4c01h
                int 21h
;                
listen3_ok :    cli
                xor ax,ax
                mov es,ax
                mov ax,es:off_int08
                mov word ptr int_timer,ax
                mov ax,es:seg_int08
                mov word ptr int_timer+2,ax
                mov word ptr es:off_int08,offset irq_0
                mov word ptr es:seg_int08,cs
                pop bx
		pop es
                pop ds
                sti
                mov cx,offset error_reset
                int 27h
main        endp
                end start
                
                                
                                                
                                
