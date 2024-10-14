cseg      segment
     assume     cs:cseg,ds:cseg
                  org  100h
start:            jmp  begin
palitra           db    80 dup ( )
attr              db    0dh
msg1              db   'Владелец MCB   Принадлежность   Число Kb   Адрес PSP   Адрес MCB',10,13,'$'
msg2              db   'SYS. CODE',10,13,'$'
msg3              db   'SYS. DATA',10,13,'$'
msg6              db   'Программа',10,13,'$'
msg7              db   '     FREE',10,13,'$'
msg8              db   'Окружение',10,13,'$'
msg_r             db   'Для продолжения нажмите любую клавишу...',10,13,'$'
table1            db   '═',10,13,'$'
names             db   8 dup (0) 
moves             db   8 dup (0)            
sizes             dw   (0);переменная хранит размер МСВ
adres_mcb         dw   (0);адрес МСВ
adres_run         dw   (0);адрес PSP
first_mcb         dw   (0);адрес первого МСВ
lines             db   (0);строка вывода
hex               db   8  dup (0)
decim             db   8  dup (0)
flag              db   0
flags             db   0
flaging           db   0 ;переменная с признаком принадлежности(окруж прогр FREE итд)
flager            db   0
sign              db   'MEMS'
begin:            push cs
                  pop  ds
                  push ds
                  pop  es
                  mov  flags,0
                  call clrscrs
                  mov  lines,4        
    
                  mov  ax,5803h;определение стратегии выделения памяти
                  mov  bx,01
                  int  21h;--------------------------------------------
                  
                  mov  ax,5200h;список списков
                  int  21h;-------------------
                  mov  es,word ptr es:[bx-2];получение адреса первого МСВ
                  mov  bx,es
                  mov  first_mcb,bx;-------------------------------------
                  mov  adres_mcb,bx
search_mcb:       mov  flaging,3;признак программы
                  call mcb;поиск next MCB и выборка всех необходимых данных из него
                  jnc  begs
                  mov  flags,1
begs:             call own_prog;процедура поиска в памяти этой программы для
                               ;записи в flaging=4 те FREE 
                  call checkit ;проверка признаков в flaging'e и формирование 
                               ;соответствующей переменной для вывода признака
;===============================================================================                
                  mov  dx,sizes
                  call bin_dec_ascii;преобразование значения sizes из bin в ascii
                  lea  dx,decim
                  call move
                  mov  dl,34
                  call out_date;вывод сайза на экран                 
;==============================================================================
                  call chk_name  ;проверка имени программы от всякой нечисти
                  lea  dx,names  
                  call move      ;пересылка нейма в переменную move 
                  mov  dl,6
                  call out_date  ;вывод нейма на экран
;==============================================================================                
                  mov  dx,adres_run
                  call bin_hex_ascii
                  lea  dx,hex
                  call move
                  mov  dl,46
                  call out_date;вывод адреса PSP      
;=============================================================================                
                  mov  dx,adres_mcb
                  call bin_hex_ascii
                  lea  dx,hex
                  call move
                  mov  dl,58
                  call out_date ;адрес MCB                                               
;===============================================================================
                  inc  lines;увеличение строки вывода
                  mov  ax,first_mcb;
                  mov  adres_mcb,ax
                  cmp  flags,1
                  jz   quit
                  cmp  lines,23
                  jne  yy
                  inc  lines
                  
                  call out_title 
                  
                  mov  ax,1003h;установка мерцания выводимого символа
                  mov  bl,1
                  int  10h;------------------------------------------
                  push es
                  push cs
                  pop  es 
                  mov  ah,13h;вывод сообщения о заполнении голубого экрана 
                  mov  al,01h                                                               
                  mov  bh,0h
                  mov  bl,08ah
                  mov  cx,40
                  mov  dh,24
                  mov  dl,5
                  mov  bp,offset msg_r
                  int  10h;------------------------------------------------
                  pop  es  
                  
                  
                  mov  ah,08h;ожидание удара по клавиатуре
                  int  21h;-------------------------------
                  
      mov  ah,06h;очистка экрана 
      mov  al,22
      mov  bh,00h
      mov  ch,4
      mov  cl,0
      mov  dh,25
      mov  dl,80
      int  10h;-------------------
      mov  lines,4;установка первоначального значения строки вывода
yy:               jmp  search_mcb ;переход на поиск следующего МСВ 
quit:             dec  lines
                  call  out_title;вавод титла две полосочки вверху и одна 
                                 ;внизу заглавная. надпись msg1
                  push es
                  push cs
                  pop  es 
                  mov  ah,13h 
                  mov  al,01h                                                               
                  mov  bh,0h
                  mov  bl,07h
                  mov  cx,80
                  mov  dh,24
                  mov  dl,1
                  mov  bp,offset palitra
                  int  10h
                  pop  es  
                                 
                  mov  ah,4ch
                  int  21h
                            mcb proc    near
                                call clears
                                mov  es,first_mcb; занесение сегм адреса MCB
			        mov  ax,first_mcb; сохранение адреса
                                mov  bx,es:[3]; 
                                mov  sizes,bx; 
                                inc  sizes   ; получение размера MCB
                                add  first_mcb,bx; 
                                inc  first_mcb; получение адреса след MCB
                                mov  bx,es:[1]   
                                mov  adres_run,bx;получение адреса PSP
                                cmp  adres_run,0;
	                        jne  a8
	                        mov  flaging,4;занесение признака FREE
	                        jmp  a2
                            a8: dec  bx
                                cmp  bx,ax
                                je  a1
                                mov  flaging,2; занесение признака окружения
                            a1: mov  ds,bx             
                                cld
                                push es
                                push cs
                                pop  es
                                mov  cx,0008h
                                mov  si,8
                                lea  di,names
                                rep  movsb
                                pop  es
   				push cs
				pop  ds
				push ax
                                mov  al,es:[8]
                                cmp  al,'S'
                                jne  z8
                                mov  al,es:[9]
                                cmp  al,'D'
                                jne  z4
                                mov  flaging,1;занесение признака SD
                                call version;определение версии DOS
                                jmp  z8
                            z4: mov  al,es:[9]
                                cmp  al,'C'
                                jne  z8
                                mov  flaging,0;занесение признака SC
                                call version;определение версии DOS
                            z8: pop  ax	
			    a2: cmp  byte ptr es:[0],5ah; проверка на 'Z'
                                jnz  a3
                                stc                     ; да
                                ret
                            a3: clc                     ; нет
                                ret
                                mcb  endp
                            chk_name     proc    near
                                         mov  di,0
                            z1:          mov  al,names[di]
                                         inc  di
                                         cmp  di,8
                                         je   z3 
                                         cmp  al,0
                                         jne  z1              
                            z2:          mov  names[di],0
                                         cmp  di,8
                                         je   z3
                                         inc  di
                                         jmp  z2 
                            z3:          ret
                            chk_name     endp                          
                            move         proc    near
                                         push cs
                                         pop  es
                                         cld
                                         mov  cx,10
                                         mov  si,dx
                                         lea  di,moves
                                         rep  movsb
                                         ret
                            move         endp                          
                            out_date     proc    near
                                         push es
                                         push cs
                                         pop  es 
                                         mov  ah,13h
                                         mov  al,01h                                                               
                                         mov  bh,0h
                                         mov  bl,attr
                                         mov  cx,8
                                         mov  dh,lines
                                         mov  bp,offset moves
                                         int  10h
                                         pop  es  
                                         ret
                            out_date     endp                 
                            out_title    proc     near
                                         call out_table
                                         mov  ah,13h
                                         mov  al,01h                                                               
                                         mov  bh,0h
                                         mov  bl,0ah
                                         mov  cx,64
                                         mov  dh,2
                                         mov  dl,2
                                         mov  bp,offset msg1
                                         int  10h        
                                         ret
                            out_title    endp
                            out_table    proc     near
                                         mov  dl,2
                                         mov  ah,13h
                                         mov  al,01h                                                               
                                         mov  bh,0h
                                         mov  bl,attr
                                         mov  cx,1
                                         mov  bp,offset table1
                            n1:          mov  dh,1
                                         int  10h   
                                         mov  dh,3
                                         int  10h
                                         inc  dl
                                         cmp  dl,66
                                         jne  n1
           				 cmp  flags,1
                                         jnz  n2
                                         mov  dl,2
                                         inc  lines
                            n3:          mov  dh,lines
                                         int  10h
                                         inc  dl
                                         cmp  dl,66
                                         jne  n3
                            n2:          ret
                            out_table    endp                  
                            clears       proc    near
                                         mov  cx,7
                                         mov  di,0
                            r1:          mov  names[di],' '
                                         mov  moves[di],' ' 
                                         inc  di
                                         loop r1
                                         ret
                            clears       endp              
                            bin_hex_ascii   proc    near
                                         push cs
                                         pop  es
                                         mov  flag,0 
                                         mov  ax,dx
                                         mov  cx,3    
                                         mov  di,0
 			    m1:          mov  hex[di],' '
                                         inc  di
                                         loop m1
					 mov  hex[3],'0'	
					 mov  hex[4],'0'
                                         mov  cx,10h
                                         mov  di,6
                            m7:          xor  dx,dx
                                         div  cx
                                         cmp  ax,0fh
                                         jg   m2
   				         mov  flag,1
		            m2:          cmp  dx,9
				         jg   m3
				         add  dx,48
				         mov  hex[di],dl
				         jmp  m4
			    m3:          add  dx,55
				         mov  hex[di],dl
			    m4:          dec  di     
				         cmp  flag,01
				         je   m8
				         jmp  m7
			    m8:          mov  hex[7],'h'
				         cmp  ax,9
				         jg   m5
				         add  ax,48
				         mov  hex[di],al
				         jmp  m6
			    m5:          add  ax,55
				         mov  hex[di],al         
			    m6:          ret
	      	   	    bin_hex_ascii     endp
                            bin_dec_ascii     proc    near
					 mov  ax,dx
					 xor  dx,dx
					 mov  bx,16
				         mul  bx
				         mov  cx,1000
         			         div  cx
         			         push ax
         			         mov  ax,dx
         			         xor  dx,dx
         			         mov  cx,100
         			         div  cx
					 add  al,48
					 mov  decim[6],al	
				         mov  di,4
				         mov  cx,10
               				 pop  ax
			    d:           xor  dx,dx  
				         div  cx
 					 add  dl,48
    				         mov  decim[di],dl
				         dec  di
				         cmp  di,0
				         jne  d
				         mov  decim[0],' '
				         mov  decim[1],' '		
                                         mov  decim[5],'.'
                                         mov  decim[7],'k'
				         ret
		            bin_dec_ascii     endp		         
		            clrscrs      proc    near
                                         mov  ax,0600h
                                         mov  dx,1950h
                                         mov  cx,0h
                                         int  10h
                                         ret
                            clrscrs      endp       
                            checkit      proc  near
                                         cmp  flaging,0
                                         jne  b0
                                         mov  bp,offset msg2
                                         jmp  exiting
                            b0:          cmp  flaging,1
                                         jne  b1
                                         mov  bp,offset msg3
                                         jmp  exiting
                            b1:          cmp  flaging,2
                                         jne  b2
                                         mov  bp,offset msg8
                                         jmp  exiting
                            b2:          cmp  flaging,3
                                         jne  b3
                            b5:          mov  bp,offset msg6 
                                         jmp  exiting
                            b3:          cmp  flaging,4
                                         jne  b5
                                         mov  cx,8
                                         mov  di,0
                            x:           mov  names[di],'-'
                                         inc  di
                                         loop x		 
                                         mov  bp,offset msg7
                            exiting:     cmp  flager,1
                                         jne  b6
                                         mov  bp,offset msg7
                            b6:          push es
                                         push cs		
                                         pop  es
                                         mov  cx,9
                                         mov  dl,22
                                         mov  ah,13h
                                         mov  al,01h                                                               
                                         mov  bh,0h
                                         mov  bl,attr
                                         mov  dh,lines
                                         int  10h
                                         pop  es              
                                         mov  flager,0
                                         ret
                            checkit      endp
                            own_prog     proc  near
                                         push  ax
                                         push  cx
                                         push  di
                                         push  si
                                         push  es
                                         mov   ax,adres_run
                                         dec   ax
                                         mov   es,ax
                                         cld
                                         mov   di,8
                                         lea   si,sign
                                         mov   cx,4
                            repe         cmpsb 
                                         jne   exiters
                                         mov  cx,8
                                         mov  di,0
                            y:           mov  names[di],'-'
                                         inc  di
                                         loop y
                                         mov   adres_run,0
                                         mov   flager,1
                            exiters:     pop   es
                                         pop   si
                                         pop   di
                                         pop   cx
                                         pop   ax
                                         ret
                            own_prog     endp
                            
                            version      proc  near
                                         push  ax
                                         push  bx
                                         push  cx
                                         mov   ax,3000h
                                         int   21h
                                         mov   names[0],'D'
                                         mov   names[1],'O'
                                         mov   names[2],'S'
                                         mov   names[3],' '
                                         mov   names[5],'.'
                                         mov   bx,ax
                                         xor   ah,ah
                                         add   al,48
                                         mov   names[4],al
                                         mov   ax,bx
                                         mov   al,ah
                                         xor   ah,ah
                                         mov   bl,10
                                         div   bl
                                         add   al,48
                                         add   ah,48
                                         mov   names[6],al
                                         mov   names[7],ah
                                         pop   cx
                                         pop   bx
                                         pop   ax 
                                         ret
                            version      endp             
cseg ends
end start                                         
                                                
        
