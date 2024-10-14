include ipxspx.inc
.286
cseg SEGMENT
ASSUME CS:cseg,DS:cseg
ORG 100h
begin:JMP start
;------------------------------------------------------------------------
comspec				     DB 30  DUP(0)
lengt_file                           DW 0
filename1			     DB 13  DUP(0)
filename2			     DB 13  DUP(0)
filename3			     DB 13  DUP(0)
buffer                               db 546 dup(0)
number_packet                        db 0
error_flag                           db 0
;------------------------------------------------------------------------
spx_load                             db           'SPX драйвер установлен'
info db           'Количество каналов: максимальное      доступное       '
version                              db              'Версия драйвера SPX'
;-------------------------------------------------------------------------
max_channell                         dw 0
free_channell                        dw 0
nversion                             dw 0

resiver                              db 'Принято пакетов с файлом'
cols                                 db 35
plus                                 db '+'
msg_spx                              db 'ЭТО - СТАНЦИЯ   ПРОТОКОЛА   SPX.'
br_spx 				     db 'Связь с мостом  установлена.    '
req_file                             DB 'Передан запрос на файл с именем'
req_file_answer                      db 'Получено подтверждение на файл '
NOT_found_file                       DB 'На сервере нет файла'

ipx_load_error_msg                   DB 'IPX драйвер не установлен.      '
SPX_unload                           db 'SPX драйвер не установлен.      '
error_03h                            db 'Поле IN_USE и ошибка функции 03h'
error_04h                            db 'Поле IN_USE и ошибка функции 04h'
error_12h                            db 'Поле IN_USE и ошибка функции 12h'
error_11h                            db 'Поле IN_USE и ошибка функции 11h'
error_17h                            db 'Поле IN_USE и ошибка функции 17h'
error_16h                            db 'Поле IN_USE и ошибка функции 16h'
error_13h                            db 'Поле IN_USE и ошибка функции 13h'
file_exist 		             DB 'Такой файл уже существует'
file_bad_msg			     DB 'Неверные параметры'
counts db 0
;-------------------------------------------------------------------------
END_work                             DB 0
flag                                 DB 0
handle				     DW	?
LastBlock			     DW ?
long                                 DW ?
;-------------------------------------------------------------------------
lines                                DB 6
error_code                           DB 0
count				     DB 0
adres   			     DW 0
SIZE_FRG			     DW 0
number_NAME_file		     DB 0
file_point                           DW 0;указатель на имя файла
net_adres                            DB 4 dup(0)
                                     DB 6 dup(255)
;--------------------------------------------------------------------
hex                                  db 4 dup(48) 
API_IPX                              DD 0
pbl_IPX_resiver                      DB 30  DUP(0)
pbl_IPX_transmit                     DB 30  DUP(0)
pbl_SPX_resiver                      DB 42  DUP(0)
ECB                                  DB 48  DUP(0)
ECB_SPX_Rs                           DB 48  DUP(0)
ECB_SPX_Rx                           DB 48  DUP(0)
ECB_SPX_Ls                           db 48  dup(0)
ECB_SPX_Lx                           db 48  dup(0)
ECB_SPX_Tr                           DB 48  DUP(0)
spx_socket                           dw 0
ipx_socket                           dw 0
source_chanell			     dw 0
dest_chanell			     dw 0
buffer_resiver                       db 546 dup(0)
buffer_transmit                      db 546 dup(0)
;-------------------------------------------------------------------------
start: 
MOV  AX,0600h
MOV  DX,1950h
MOV  CX,0h
MOV  BX,0700h
INT  10h
MOV  DX,0102h
MOV  CX,32
MOV  BP,offset msg_spx
CALL OUT_date
CALL IPX_load
JNC  well
JMP  NEAR PTR quit
well:
CALL SPX_check
JNC  wells
JMP  NEAR PTR quit
wells:

PUSH CS
POP  ES
;--------------------------------------------------------------------
CALL comstroc				;выделение имен файлов
CMP  error_code,0
JE   well1
JMP  NEAR PTR quit
well1:
MOV  DX,0202h
MOV  CX,31
MOV  BP,OFFSET req_file
CALL OUT_date
MOV  DX,0223h
MOV  CX,13
MOV  BP,OFFSET filename1
CALL OUT_date
MOV  BX,IPXGetInternetworkAddress	;получить адрес станции
MOV  SI,OFFSET pbl_IPX_transmit[18]	;в сети на которой работает
CALL [API_IPX]				;эта программа
;--------------------------------------------------------------------
mov  dx,7878h
call ipx_socket_open
mov  ipx_socket,dx	 		;номер сокета 6666h
mov  dx,5858h
call ipx_socket_open
mov  spx_socket,dx			;номер сокета 4444h
;--------------------------------------------------------------------
CLD
MOV  CX,6
MOV  DI,OFFSET ecb[28]
MOV  SI,OFFSET net_adres[4]		;заполняем поле
REP  MOVSB				;ImmAddress в ECB[28]
CLD					;широковещательным адресом
MOV  CX,10
MOV  DI,OFFSET pbl_IPX_transmit[6]
MOV  SI,OFFSET net_adres
REP  MOVSB
;--------------------------------------------------------------------
MOV  BX,13
MOV  DX,OFFSET filename1
MOV  CX,02h
CALL ipx_send				;посылка пакета
mov  bp,offset error_03h
mov  si,offset ecb
CALL waitings
cmp  error_flag,1
jne  ready
jmp  near ptr bad
ready:
;--------------------------------------------------------------------
MOV  BX,512
MOV  CX,2
MOV  DX,OFFSET filename3
CALL ipx_listen				;прием пакета
mov  bp,offset error_04h
mov  si,offset ecb
CALL waitings				;ожидание прихода пакета
cmp  error_flag,1
jne  ready1
jmp  near ptr bad
ready1:

;--------------------------------------------------------------------
MOV  DX,0302h
MOV  CX,32
MOV  BP,OFFSET br_spx
CALL OUT_date
;--------------------------------------------------------------------
CLD
MOV  DI,OFFSET filename1
MOV  SI,OFFSET filename3
MOV  CX,13;lengt_file
REPE CMPSB
JnE  cont8
;--------------------------------------------------------------------
MOV  DX,file_point			;
CALL creat_file
MOV  DX,file_point
CALL open_file						;
mov  dx,0402h
mov  cx,31
mov  bp,offset req_file_answer
call out_date
MOV  DX,0423h
MOV  CX,13
MOV  BP,OFFSET filename3
CALL OUT_date
JMP  repeater
;--------------------------------------------------------------------
cont8:
MOV  DX,0402h
MOV  CX,20
MOV  BP,OFFSET NOT_found_file;на сервере файл не найден
CALL OUT_date
MOV  DX,0417h
MOV  CX,13
MOV  BP,OFFSET filename1
CALL OUT_date
JMP  quit
;--------------------------------------------------------------------
repeater:
mov  cx,02h
mov  bx,512
mov  dx,offset buffer_resiver
mov  si,offset ecb_spx_rx
call SPX_listen_for_sequenced_packet 
mov  cx,02h
mov  bx,512
mov  dx,offset buffer_resiver
mov  si,offset ecb_spx_ls
call SPX_listen_for_sequenced_packet 
;;--------------------------------------------------------------------
mov  cx,01h
mov  bx,0
mov  dx,0
mov  si,offset ecb_spx_rs
call SPX_Listen_For_Connection
mov  bp,offset error_12h
mov  si,offset ecb_spx_rs
call waitings
cmp  error_flag,1
jne  ready2
jmp  near ptr bad
ready2:

MOV  DX,0902h
MOV  CX,32
MOV  BP,OFFSET br_spx
CALL OUT_date
;--------------------------------------------------------------------
next:
mov  cx,02h
mov  bx,536
mov  dx,offset buffer_resiver
mov  si,offset ecb_spx_rs
call SPX_listen_for_sequenced_packet

mov  bp,offset error_17h
mov  si,offset ecb_spx_rs
call waitings

cmp  error_flag,1
jne  ready3
jmp  near ptr bad
ready3:

MOV  AX,WORD PTR pbl_spx_resiver[2]
xchg ah,al
SUB  AX,42
MOV  long,AX
CALL write_file

MOV  DX,0a02h
MOV  CX,24
MOV  BP,OFFSET resiver
CALL OUT_date
MOV  Dh,0ah
mov  dl,cols
inc  cols
MOV  CX,1
MOV  BP,OFFSET plus
CALL OUT_date
MOV  AX,long
CMP  AX,512
je   next
bad:
call close_file
mov  dx,ipx_socket
call ipx_socket_close   		;номер сокета 7777h
mov  dx,spx_socket
call ipx_socket_close			;номер сокета 5656h
quit:
MOV  AH,4ch
INT  21h
comstroc PROC
        MOV CL,ES:[80h];
	CMP CL,00h
	JNG c1
cont:	MOV  number_NAME_file,1
        CLD
        MOV SI,82h
	LEA DI,comspec
	REP MOVSB
	MOV BL,32
	MOV [DI-1],BL
	LEA CX,filename1
	MOV DI,0
;имя  1-го файла
	LEA SI,comspec
c2:	MOV BX,ES:[SI]
	CMP BL,32
	JE  c3
	CMP BL,0
	JE  c1
c4:	MOV OFFSET filename1[DI],BL
	INC SI
	INC DI
	MOV lengt_file,DI
	JMP c2
c3:	INC SI
	XOR DI,DI
;имя 2-го файла

c6:	MOV BX,ES:[SI]
	CMP BL,32
	JE  c1
	CMP BL,0
	JNE c5
	JMP c1
c5:	MOV number_NAME_file,2
        MOV OFFSET filename2[DI],BL
	INC DI
	INC SI
	JMP c6
	
c1:     CMP  number_NAME_file,0
        JNE  c7
        MOV  CX,18
        MOV  DX,0c02h
        MOV  BP,OFFSET file_bad_msg
        CALL OUT_date
        MOV  error_code,1
        JMP  quit_comstroc
c7:     CMP  number_NAME_file,1
        JNE  c8
        MOV  DX,OFFSET filename1
        JMP  c9
c8:     MOV  DX,OFFSET filename2
c9:     MOV  file_point,DX
        MOV  AH,4eh
        MOV  CX,0
        INT  21h
        JC   quit_comstroc
        MOV  CX,25
        MOV  DX,1402h
        MOV  BP,OFFSET file_exist;такой файл есть
        CALL OUT_date
quit_comstroc:RET
comstroc ENDP      
OUT_date     PROC
      PUSH ES
      PUSH CS
      POP  ES
      MOV  AX,1301h
      MOV  BX,00fh
      INT  10h
      POP  ES
      RET
OUT_date     ENDP                 
ipx_load PROC
      MOV  AX,SEARCH_IPX
      INT  2fh
      CMP  AL,0ffh
      JNE  error
      MOV  WORD PTR API_IPX+2,ES
      MOV  WORD PTR API_IPX,DI
      CLC
      JMP  exit
error:MOV  DX,1402h
      MOV  CX,25
      MOV  AX,1301h
      MOV  BX,00fh
      MOV  BP,OFFSET ipx_load_error_msg
      INT  10h
      STC
exit: RET
ipx_load ENDP
creat_file      PROC    NEAR
		PUSHA   		;создание файла
		MOV     AH,3ch		;параметр адрес имени файла
		MOV     CX,0h		;в регистр DX
		INT     21h
		MOV     handle,AX
		POPA
		RET
creat_file	ENDP	 		
open_file       PROC
                PUSHA
		MOV	AH,3dh		;параметр адрес имени файла
		MOV	AL,01h		;в регистр DX
		INT	21h
		MOV	handle,AX
		POPA    
		RET
open_file       ENDP
write_file      PROC
		PUSHA
;-------------------запись в файл------------------------------------		
		MOV	CX,long
		MOV     AH,40h
		MOV	BX,handle
		MOV	DX,OFFSET buffer_resiver
		INT	21h
		MOV     lastblock,AX
		POPA
		RET
write_file      ENDP		
Close_file	PROC 	NEAR
		PUSHA
		MOV  	AH,3eh
		MOV	BX,handle
		INT     21h
		POPA
		RET
Close_file	ENDP	
ipx_send PROC
;--------------------------------------------------------------------
XOR  AX,AX              	     	;подготовка блока ECB
MOV  WORD PTR ECB[6],AX			;для передачи пакета серверу
MOV  WORD PTR ECB[4],AX
mov  ax,ipx_socket
mov  word ptr ecb[10],ax
mov  word ptr pbl_ipx_transmit[28],ax
;--------------------------------------------------------------------
MOV  WORD PTR ECB[34],CX		;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  WORD PTR ecb[38],CS		;поле Adress 1 сегмент
MOV  WORD PTR ecb[36],OFFSET pbl_IPX_transmit 	;поле Adress 1 смещение
MOV  WORD PTR ecb[40],30		;поле SIZE 1
;--------------------------------------------------------------------
MOV  WORD PTR ecb[44],CS		;поле Adress 2 сегмент
MOV  WORD PTR ecb[42],DX        	;поле Adress 2 смещение
MOV  WORD PTR ecb[46],BX  		;поле SIZE 2
;-----------------------		;подготовка IPX заголовка
MOV  pbl_IPX_transmit[5],4		;тип пакета
;-------------------------------	;заполнение поля 
MOV  AX,7777h				;destsocket в заголовке IPX
MOV  WORD PTR pbl_IPX_transmit[16],AX	;
;--------------------------------------------------------------------
MOV  BX,IPXSendPacket
MOV  SI,OFFSET ECB
CALL [API_IPX]
RET
ipx_send ENDP
;-------------------------------------------------
ipx_listen PROC
XOR  AX,AX
MOV  WORD PTR ECB[6],AX
MOV  WORD PTR ECB[4],AX
mov  ax,ipx_socket
mov  word ptr ecb[10],ax
;--------------------------------------------------------------------
MOV  WORD PTR ECB[34],CX  		;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  WORD PTR ecb[36],OFFSET pbl_ipx_resiver	;поле Adress сегмент
MOV  WORD PTR ECB[38],CS
MOV  WORD PTR ecb[40],30		;поле SIZE
;--------------------------------------------------------------------
MOV  WORD PTR ecb[42],DX		;поле Adress сегмент
MOV  WORD PTR ECB[44],CS
MOV  WORD PTR ecb[46],BX		;поле SIZE
;--------------------------------------------------------------------
MOV  BX,IPXListen			;вызов функции ожидания пакета от
MOV  SI,OFFSET ECB			;передающей станции
CALL [API_IPX]
RET					;----------------------------
ipx_listen ENDP	
IPX_socket_open proc
MOV  BX,IPXOpenSocket
MOV  AL,0ffh
CALL [API_IPX]				;открываем сокет
ret
IPX_socket_open endp
IPX_socket_close proc
MOV  BX,IPXcloseSocket
CALL [API_IPX]				;открываем сокет
ret
IPX_socket_close endp
SPX_listen_for_sequenced_packet proc
pusha
XOR  AX,AX
MOV  si[6],AX
MOV  si[4],AX
mov  ax,SPX_socket
mov  si[10],ax
;--------------------------------------------------------------------
MOV  si[34],CX  	;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  si[36],OFFSET pbl_spx_resiver	;поле Adress сегмент
MOV  si[38],CS
mov  ax,42
MOV  si[40],ax		;поле SIZE
;--------------------------------------------------------------------
MOV  si[42],DX		;поле Adress сегмент
MOV  si[44],CS
MOV  si[46],BX		;поле SIZE
mov  bx,SPXListenForSequencedPacket
call [API_IPX]
popa
ret
SPX_listen_for_sequenced_packet endp
;--------------------------------------------------------------------
SPX_listen_for_connection proc
pusha
XOR  AX,AX
MOV  si[6],AX
MOV  si[4],AX
mov  ax,SPX_socket
mov  si[10],ax
;--------------------------------------------------------------------
MOV  si[34],CX  	;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  si[36],OFFSET pbl_spx_resiver	;поле Adress сегмент
MOV  si[38],CS
mov  ax,42
MOV  si[40],ax		;поле SIZE
;--------------------------------------------------------------------
MOV  si[42],DX		;поле Adress сегмент
MOV  si[44],CS
MOV  si[46],BX		;поле SIZE
mov  al,10h
mov  ah,0ffh
mov  bx,SPXListenForConnection
call [API_IPX]
popa
ret
SPX_listen_for_connection endp
waitings PROC
pusha
waitings1:
MOV  BX,IPXRelinquishControl
CALL [API_IPX]
push bp
mov  dh,22
mov  cx,32
mov  dl,02
call out_date
mov  bl,si[9]
mov  bh,si[8]
call bin_hex_ascii
mov  cx,4
mov  dl,36
mov  bp,offset hex
call out_date
pop  bp
mov  al,si[8]
CMP  al,0
je   wait_quit
push  es
      xor  ax,ax
      mov  es,ax
      mov  al,es:[417h]
pop   es      
      cmp  al,5
JNE  waitings1		;ожидание прихода пакета
mov  error_flag,1
wait_quit:
popa
RET
waitings ENDP
bin_hex_ascii proc
      pusha
      push cx
      push di
      mov  di,0
agn:  mov  hex[di],48
      inc  di
      cmp  di,3
      jne  agn
      mov  flag,0 
      mov  ax,bx
      mov  cx,10h
      mov  di,3
mcb11:xor  dx,dx
      div  cx
      cmp  ax,0fh
      jg   mcb12
      mov  flag,1
mcb12:cmp  dx,9
      jg   mcb13
      add  dx,48
      mov  hex[di],dl
      jmp  mcb14
mcb13:add  dx,55
      mov  hex[di],dl
mcb14:dec  di     
      cmp  flag,01
      je   mcb15
      jmp  mcb11
mcb15:cmp  ax,9
      jg   mcb16
      add  ax,48
      mov  hex[di],al
      jmp  mcb17
mcb16:add  ax,55
      mov  hex[di],al         
mcb17:pop  di
      pop  cx
      popa
      ret
bin_hex_ascii endp
spx_check proc
	mov al,00
	mov bx,SPXCheckInstallation
	call [API_IPX] 
	
	cmp  al,0ffh
	jne  bads
	mov  max_channell,cx
	mov  free_channell,dx
	mov  nversion,bx
	mov  bp,offset spx_load
	mov  dx,01402h
	mov  cx,22
	call out_date
	mov  bp,offset info
	mov  dx,01502h
	mov  cx,47
	call out_date
        mov  bx,max_channell
        call bin_hex_ascii
	mov  bp,offset hex
	mov  dx,01523h
	mov  cx,4
	call out_date
	Mov  bx,free_channell
        call bin_hex_ascii
	mov  bp,offset hex
	mov  dx,01532h
	mov  cx,4
	call out_date
	mov  bp,offset version
	mov  dx,01602h
	mov  cx,19
	call out_date
        Mov  bx,nversion
        call bin_hex_ascii
	mov  bp,offset hex
	mov  dx,01616h
	mov  cx,4
	call out_date
	clc
	ret
	bads:
	mov  bp,offset spx_unload
	mov  dx,01402h
	mov  cx,25
	call out_date
        stc
        ret	
	spx_check endp

cseg ENDS
END begin