cseg  segment
            assume cs:cseg,ds:cseg,es:cseg
            org  100h
start:      jmp  init
times       db   8  dup (0)
old_1ch     dd   0      
old_4ah     dd   0
old_pos     dw   0
sign        db   'TIMERS'
msg         db   'Программа уже установлена',10,13,'$' 
msg_err     db   'Неверные параметры для работы',10,13,'$'
new_4ah proc
      push ax
      push dx
            MOV  DX,1000          ;счетчик числа циклов
            IN   AL,61H          ;читаем порт B 8255
            AND  AL,0FEH         ;выключаем бит таймера 8253
s1:         OR   AL,2            ;включаем бит динамика
            OUT  61H,AL          ;посылаем байт в порт B
            MOV  CX,2500         ;длительность первой половины
s3:         LOOP s3              ;задержка пока сигнал высокий
            AND  AL,0FDH         ;выключаем бит динамика
            OUT  61H,AL          ;посылаем байт в порт B
s2:         LOOP s2              ;задержка пока сигнал низкий
            DEC  DX              ;уменьшаем счетчик циклов
            JNZ  s1              ;повторяем цикл пока DX не 0
      pop dx
      pop ax
      jmp cs:old_4ah
new_4ah endp	
new_1ch proc
      push ax
      push bx
      push cx
      push dx
      push ds
      push cs
      pop  ds
      push es
      push cs
      pop  es
      mov  times[2],58
      mov  times[5],58
      mov  ah,02h
      int  1ah
      push cx
      mov  ax,cx
      mov  bx,cx
      xor  ch,ch
      mov  cl,4
;==============================================================================         
      and  ah,0f0h  ;десятки часов
      shr  ah,cl
      add  ah,48
      mov  times[0],ah
;==============================================================================         
      mov  ax,bx    ;единицы часов
      and  ah,00fh
      add  ah,48  
      mov  times[1],ah
;==============================================================================         
      mov  ax,bx    ;десятки минут
      and  al,0f0h
      shr  al,cl
      add  al,48
      mov  times[3],al
;===============================================================================         
      mov  ax,bx    ;единицы минут
      and  al,00fh 
      add  al,48
      mov  times[4],al
;==============================================================================         
      mov  ah,dh    ;десятки секунд
      and  ah,0f0h
      shr  ah,cl
      add  ah,48
      mov  times[6],ah
;==============================================================================         
      mov  ah,dh    ;единицы секунд
      and  ah,00fh
      add  ah,48
      mov  times[7],ah         
;==============================================================================         
      mov  ah,03h
      mov  bh,0
      int  10h
      mov  old_pos,dx
      pop  cx
      mov  bl,04ah
      mov  ah,13h
      mov  al,01h
      mov  bh,0h
      mov  cx,8
      mov  dh,0
      mov  dl,72
      mov  bp,offset times
      int  10h
      mov  ah,02h
      mov  bh,0
      mov  dx,old_pos
      int  10h
      pop  es
      pop  ds
      pop  dx
      pop  cx
      pop  bx
      pop  ax
      jmp  cs:old_1ch
new_1ch endp
init              proc 
                  mov  ah,es:[83h]
                  cmp  ah,'a'
                  je   next_t
                  cmp  ah,'n'
                  je   runs
                  jmp  exit_err
next_t:           push es
                  mov  ax,5200h
                  int  21h
                  mov  es,word ptr es:[bx-2]
                  mov  ax,es
next:             mov  es,ax     
                  mov  ch,es:[0]
                  cmp  ch,5ah
                  je   runs
                  mov  bx,es:[3]
                  add  ax,bx
                  inc  ax                   ; получение адреса след MCB
                  cld
                  mov   di,8
                  lea   si,sign
                  mov   cx,6
     repe         cmpsb 
                  jne   next
                  pop  es
                  mov  ah,09h
                  mov  dx,offset msg
                  int  21h
                  mov  ah,4ch
                  int  21h 
;=============================================================================
runs:             mov  ah,07h
                  int  1ah                                    
;==============================================================================                  
                  mov  ah,ds:[85h]
                  sub  ah,30h
                  mov  cl,4
                  sal  ah,cl
                  mov  al,ds:[86h]
                  sub  al,30h
                  or   ah,al
                  mov  ch,ah
;==============================================================================                  
                  mov  ah,ds:[88h]
                  sub  ah,30h
                  mov  cl,4
                  sal  ah,cl
                  mov  al,ds:[89h]
                  sub  al,30h
                  or   ah,al
                  mov  cl,ah
;==============================================================================
                  mov  dx,0100h
                  mov  ax,0
                  mov  bx,0
                  mov  ah,06h
                  int  1ah        
                  mov  ah,es:[83h]
                  cmp  ah,'n'
                  je   exit
;==============================================================================
    	 	  mov  ah,35h
    	 	  mov  al,1ch
    	 	  int  21h
    	 	  mov  word ptr old_1ch,bx 		   
    	 	  mov  word ptr old_1ch+2,es    	 
    	 	  mov  ah,25h
    	 	  mov  al,1ch
    	 	  mov  dx,offset new_1ch
    	 	  int  21h  
;==============================================================================
    	 	  mov  ah,35h
    	 	  mov  al,4ah
    	 	  int  21h
    	 	  mov  word ptr old_4ah,bx
    	 	  mov  word ptr old_4ah+2,es    	 
    	 	  mov  ah,25h
    	 	  mov  al,4ah
    	 	  mov  dx,offset new_4ah
    	 	  push ds
    	 	  push cs
    	 	  pop  ds
    	 	  int  21h  
    	 	  pop  ds
;==============================================================================    	 	  
                  mov  ax,3100h
		  mov  dx,(init-start+10fh)/16
		  int  21h
exit_err:         mov  ah,09h
                  lea  dx,msg_err
                  int  21h
exit:             mov  ah,4ch
                  int  21h 	;запуск возможен либо клавишей ENTER без установки таймера	  
init              endp          ;либо с параметрами /a:hh:mm(hh:mm время включения таймера) при первоначальной установке
cseg              ends          ;программы с одновременной установкой таймера
end               start         ;возможна переустановка таймера с помощью /n:hh:mm(hh:mm как и у параметра а)