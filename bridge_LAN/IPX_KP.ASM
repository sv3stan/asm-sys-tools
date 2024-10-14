include ipxspx.inc
.286
cseg SEGMENT
ASSUME CS:cseg,DS:cseg
ORG 100h
begin:JMP start
;------------------------------------------------------------------------
transmit                             db 'Передано пакетов с файлом'
msg_ipx                              db 'ЭТО  ПРОГРАММА  ПРОТОКОЛА  IPX  '
ipx_load_error_msg                   DB 'IPX драйвер не установлен.      '
file_bad_msg			     DB 'Неверные параметры.             '
WAIT_msg                             DB 'Подождите. Идет передача.       '
rk_ipx                               DB 'Связь с мостом установлена'
error_03h                            db 'Поле IN_USE и ошибка функции 03h'
error_04h                            db 'Поле IN_USE и ошибка функции 04h'
file_search                          DB 'На  станции   IPX  открыт  файл '
error_open_file                      DB 'Невозможно открыть файл'
req_file                             DB 'Пришел запрос на файл'
;-------------------------------------------------------------------------
time                                 dw 5
error_flag                           db 0
col1                                 db 30
cols                                 db '+'
END_work                             DB 0
flag                                 DB 0
handle				     DW	?
LastBlock			     DW ?
file_NAME			     DB 13  DUP(0)
;-------------------------------------------------------------------------
notfound                             DB 'notfound file'
exit_flag                            DB 0
hex                                  db 4 dup(48) 
API_IPX                              DD 0
pbl_IPX_resiver                      DB 30  DUP(0)
pbl_IPX_transmit                     DB 30  DUP(0)
ECB                                  DB 48  DUP(0)
ipx_socket                           dw 0
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
MOV  BP,OFFSET msg_ipx
CALL OUT_date
CALL IPX_load
JNC  well
JMP  NEAR PTR quit
well:
PUSH CS
POP  ES
MOV  BX,IPXGetInternetworkAddress	;получить адрес станции
MOV  SI,OFFSET pbl_IPX_transmit[18]	;в сети на которой работает
CALL [API_IPX]				;эта программа
mov  dx,7676h
call ipx_socket_open
mov  ipx_socket,dx			;номер сокета 6666h
;--------------------------------------------------------------------
MOV  BX,13
MOV  CX,02h
MOV  DX,OFFSET file_NAME
CALL ipx_listen
mov  bp,offset error_04h
mov  si,offset ecb
CALL waitings   		;ожидание прихода пакета
cmp  error_flag,1
jne  ready
jmp  near ptr bad
ready:
;--------------------------------------------------------------------
MOV  DX,0202h
MOV  CX,21
MOV  BP,OFFSET req_file
CALL OUT_date
MOV  DX,0219h
MOV  CX,13
MOV  BP,OFFSET file_NAME
CALL OUT_date
MOV  DX,OFFSET file_NAME
CALL open_file
JC   wells1
;--------------------------------------------------------------------
MOV  DX,0302h
MOV  CX,31
MOV  BP,OFFSET file_search
CALL OUT_date
MOV  DX,0323h
MOV  CX,13
MOV  BP,OFFSET file_NAME
CALL OUT_date
MOV  exit_flag,0
MOV  BX,13
MOV  CX,02h
MOV  DX,OFFSET file_NAME
JMP  process
;--------------------------------------------------------------------
wells1:
MOV  DX,0302h
MOV  CX,23
MOV  BP,OFFSET error_open_file
CALL OUT_date
MOV  DX,031bh
MOV  CX,13
MOV  BP,OFFSET file_NAME
CALL OUT_date
MOV  CX,02h
MOV  BX,13
MOV  DX,OFFSET notfound
MOV  exit_flag,1
;--------------------------------------------------------------------
process:
call delays
CALL ipx_send				;посылка пакета
mov  bp,offset error_03h
mov  si,offset ecb
CALL waitings
cmp  error_flag,1
jne   ready1
jmp  near ptr bad
ready1:

;--------------------------------------------------------------------
MOV  DX,0402h
MOV  CX,26
MOV  BP,OFFSET rk_ipx
CALL OUT_date
CMP  exit_flag,1
JnE  repeater
jmp  near ptr bad
;--------------------------------------------------------------------
repeater:
;--------------------------------------------------------------------
MOV  CX,01h
CALL ipx_listen
;--------------------------------------------------------------------
mov  bp,offset error_04h
mov  si,offset ecb
CALL waitings   		;ожидание прихода пакета
cmp  error_flag,1
jne   ready2
jmp  near ptr bad
ready2:

;--------------------------------------------------------------------
call delays
CALL read_file
MOV  BX,lastblock
MOV  CX,02h
MOV  DX,OFFSET buffer_transmit
;;--------------------------------------------------------------------
CALL ipx_send				;посылка пакета
;;--------------------------------------------------------------------
mov  bp,offset error_03h
mov  si,offset ecb
CALL waitings
cmp  error_flag,1
jne   ready3
jmp  near ptr bad
ready3:

;--------------------------------------------------------------------
MOV  DX,0502h
MOV  CX,25
MOV  BP,OFFSET transmit
CALL OUT_date
MOV  DL,col1
MOV  DH,05h
MOV  CX,1
MOV  BP,OFFSET cols
CALL OUT_date
inc  col1
mov  ax,lastblock
CMP  ax,512
JnE  bad
;--------------------------------------------------------------------
JMP  repeater
bad:
mov  dx,ipx_socket
call ipx_socket_close   		
quit:
CALL close_file
MOV  AH,4ch
INT  21h
;--------------------------------------------------------------------
OUT_date   PROC
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
open_file       PROC
                PUSHA
		MOV	AH,3dh		;параметр адрес имени файла
		MOV	AL,0		;в регистр DX
		INT	21h
		JC      quit_open_file
		MOV	handle,AX
		CLC
		POPA    
		RET
quit_open_file: STC
                POPA
                RET
open_file       ENDP
read_file	PROC	NEAR
	        PUSHA
;------------------чтение файла---------------------------------------
		MOV	AH,3fh
		MOV	BX,handle
		MOV	CX,512
		MOV	DX,OFFSET buffer_transmit
		INT	21h
		MOV	LastBlock,AX
		POPA
		RET
read_file	ENDP		
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
CLD
MOV  CX,6
MOV  DI,OFFSET ecb[28]
MOV  SI,OFFSET pbl_ipx_resiver[22]
REP  MOVSB
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
MOV  AX,WORD PTR pbl_ipx_resiver[28]	;destsocket в заголовке IPX
MOV  WORD PTR pbl_IPX_transmit[16],AX
;--------------------------------------------------------------------
CLD
MOV  CX,10
MOV  DI,OFFSET pbl_IPX_transmit[6]
MOV  SI,OFFSET pbl_IPX_resiver[18]
REP  MOVSB
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
waitings PROC
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
Jne   waitings1		;ожидание прихода пакета
mov   error_flag,1
wait_quit:
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
delays proc
pusha
mov ah,0
int 1ah
mov bx,dx
add bx,time
m1:
mov ah,0
int 1ah
cmp bx,dx
jne m1
popa
ret
delays endp

cseg ENDS
END begin