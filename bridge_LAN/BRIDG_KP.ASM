include ipxspx.inc
.286
cseg SEGMENT
ASSUME CS:cseg,DS:cseg
ORG 100h
begin:JMP start
;------------------------------------------------------------------------
spx_load                             db           'SPX драйвер установлен'
info db           'Количество каналов: максимальное      доступное       '
version                              db              'Версия драйвера SPX'
;-------------------------------------------------------------------------
time                                 dw 5
exit_flag                            db 0
max_channell                         dw 0
free_channell                        dw 0
nversion                             dw 0
retranslation                        db 'Ретранслировано пакетов'
retru db 'пакетов ретранслировано'
cols                                 db 28
plus                                 db '+'
error_open_file                      DB 'Невозможно открыть файл         '
req_file                             DB 'Ретранслирован   запрос на  файл' 
req_file_rk                          DB 'Ретранслирован   ответ  на  файл' 
msg_bridge                           db 'ЭТО - СТАНЦИЯ МОСТ.'
ipx_load_error_msg                   DB 'IPX драйвер не установлен.      '
SPX_unload                           db 'SPX драйвер не установлен.      '
spx_br                               db 'Связь с станцией SPX установлена'
ipx_br                               db 'Связь с станцией IPX установлена'
BEGIN_transmit              db 'Для начала передачи нажмите любую клавишу'
error_03h                            db 'Поле IN_USE и ошибка функции 03h'
error_04h                            db 'Поле IN_USE и ошибка функции 04h'
error_12h                            db 'Поле IN_USE и ошибка функции 12h'
error_11h                            db 'Поле IN_USE и ошибка функции 11h'
error_17h                            db 'Поле IN_USE и ошибка функции 17h'
error_16h                            db 'Поле IN_USE и ошибка функции 16h'
error_13h                            db 'Поле IN_USE и ошибка функции 13h'
;-------------------------------------------------------------------------
lines                                DB 6
END_work                             DB 0
long                                 dw 0
flag                                 DB 0
handle				     DW	?
LastBlock			     DW ?
file_NAME			     DB 13  DUP(0)
file_name1                           db 13 dup(0)
net_adres                            db 4   dup(0)
                                     db 6   dup(255)
;-------------------------------------------------------------------------
count				     DB 0
SIZE_FRG			     DW 0
hex                                  db 4 dup(48) 
API_IPX                              DD 0
pbl_IPX_resiver_ipx                  DB 30  DUP(0)
pbl_IPX_transmit_ipx                 DB 30  DUP(0)
pbl_IPX_resiver_spx                  DB 30  DUP(0)
pbl_IPX_transmit_spx                 DB 30  DUP(0)
pbl_SPX_resiver                      DB 42  DUP(0)
pbl_SPX_transmit                     DB 42  DUP(0)
ECB                                  DB 48  DUP(0)
ECB_SPX_Rs                           DB 48  DUP(0)
ECB_SPX_Ls                           db 48  dup(0)
ECB_SPX_Tr                           DB 48  DUP(0)
ECB_SPX_Tx                           DB 48  DUP(0)
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
MOV  CX,19
MOV  BP,OFFSET msg_bridge
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
MOV  BX,IPXGetInternetworkAddress	;получить адрес станции
MOV  SI,OFFSET pbl_IPX_transmit_spx[18]	;в сети на которой работает
CALL [API_IPX]				;эта программа
mov  dx,7777h
call ipx_socket_open
mov  ipx_socket,dx			;номер сокета 6666h
mov  dx,5757h
call ipx_socket_open
mov  spx_socket,dx			;номер сокета 4444h
;--------------------------------------------------------------------
XOR  AX,AX
MOV  WORD PTR ECB[6],AX
MOV  WORD PTR ECB[4],AX
mov  ax,ipx_socket
mov  word ptr ecb[10],ax
;--------------------------------------------------------------------
mov  ax,02h
MOV  WORD PTR ECB[34],aX  		;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  WORD PTR ecb[36],OFFSET pbl_ipx_resiver_spx;поле Adress сегмент
MOV  WORD PTR ECB[38],CS
MOV  WORD PTR ecb[40],30		;поле SIZE
;--------------------------------------------------------------------
MOV  WORD PTR ecb[42],OFFSET file_NAME	;поле Adress сегмент
MOV  WORD PTR ECB[44],CS
mov  ax,13
MOV  WORD PTR ecb[46],ax		;поле SIZE
;--------------------------------------------------------------------
MOV  BX,IPXListen			;вызов функции ожидания пакета от
MOV  SI,OFFSET ECB			;передающей станции
CALL [API_IPX]
;-------------------------------------------------
mov  bp,offset error_04h
mov  si,offset ecb
CALL waitings   		;ожидание прихода пакета от станции SPX
cmp  exit_flag,1
jne  ready
jmp  near ptr quit
ready:
;-------------------------------------------------
CLD
MOV  CX,6
MOV  DI,OFFSET ecb[28]
MOV  SI,OFFSET net_adres[4]			;заполняем поле
REP  MOVSB					;ImmAddress в ECB[28]
CLD						;широковещательным адресом
MOV  CX,10
MOV  DI,OFFSET pbl_IPX_transmit_ipx[6]
MOV  SI,OFFSET net_adres
REP  MOVSB
mov  cx,02h
lea  dx,file_name
mov  bx,13
call ipx_send_ipx

mov  bp,offset error_03h
mov  si,offset ecb
CALL waitings   		
cmp  exit_flag,1
jne  ready1
jmp  near ptr quit
ready1:

mov  bp,offset req_file
mov  dx,0202h
mov  cx,32
CALL out_date   		;ожидание прихода пакета от станции ipx
mov  bp,offset file_name
mov  dx,0225h
mov  cx,13
CALL out_date   	


mov  cx,02h
lea  dx,file_name1
mov  bx,13
call ipx_listen_ipx


mov  bp,offset error_04h
mov  si,offset ecb
CALL waitings   		;ожидание прихода пакета от станции ipx
cmp  exit_flag,1
jne  ready2
jmp  near ptr quit
ready2:

MOV  DX,0302h
MOV  CX,32
MOV  BP,OFFSET ipx_br
CALL OUT_date

;-------------------------------------------------
process:
XOR  AX,AX              	     	;подготовка блока ECB
MOV  WORD PTR ECB[6],AX			;для передачи пакета серверу
MOV  WORD PTR ECB[4],AX
mov  ax,ipx_socket
mov  word ptr ecb[10],ax
mov  word ptr pbl_ipx_transmit_spx[28],ax
;--------------------------------------------------------------------
mov  ax,02h
MOV  WORD PTR ECB[34],aX		;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
CLD
MOV  CX,6
MOV  DI,OFFSET ecb[28]
MOV  SI,OFFSET pbl_ipx_resiver_spx[22]
REP  MOVSB
;--------------------------------------------------------------------
MOV  WORD PTR ecb[38],CS		;поле Adress 1 сегмент
MOV  WORD PTR ecb[36],OFFSET pbl_IPX_transmit_spx;поле Adress 1 смещение
MOV  WORD PTR ecb[40],30		;поле SIZE 1
;--------------------------------------------------------------------
MOV  WORD PTR ecb[44],CS		;поле Adress 2 сегмент
MOV  WORD PTR ecb[42],offset file_name1	;поле Adress 2 смещение
MOV  WORD PTR ecb[46],13  		;поле SIZE 2
;-----------------------		;подготовка IPX заголовка
MOV  pbl_IPX_transmit_spx[5],4		;тип пакета
;-------------------------------	;заполнение поля 
MOV  AX,WORD PTR pbl_ipx_resiver_spx[28];destsocket в заголовке IPX
MOV  WORD PTR pbl_IPX_transmit_spx[16],AX
;--------------------------------------------------------------------
CLD
MOV  CX,10
MOV  DI,OFFSET pbl_IPX_transmit_spx[6]
MOV  SI,OFFSET pbl_IPX_resiver_spx[18]
REP  MOVSB
;--------------------------------------------------------------------
MOV  BX,IPXSendPacket
MOV  SI,OFFSET ECB
CALL [API_IPX]
;--------------------------------------------------------------------
mov  bp,offset error_03h
mov  si,offset ecb
CALL waitings
cmp  exit_flag,1
jne  ready3
jmp  near ptr quit
ready3:

mov  bp,offset req_file_rk
mov  dx,0402h
mov  cx,32
CALL out_date   		;
mov  bp,offset file_name1
mov  dx,0425h
mov  cx,13
CALL out_date   	

cld  
mov  cx,13
lea  si,file_name
lea  di,file_name1
repe cmpsb
JE   good_file
jmp  near ptr bad
;--------------------------------------------------------------------
good_file:
mov  cx,02h
mov  bx,512
mov  dx,offset buffer_resiver
mov  si,offset ecb_spx_rs
call SPX_listen_for_sequenced_packet 
mov  cx,02h
mov  bx,512
mov  dx,offset buffer_resiver
mov  si,offset ecb_spx_ls
call SPX_listen_for_sequenced_packet
;--------------------------------------------------------------------
repeater:
call delays
mov  cx,01h
mov  bx,0
mov  dx,0
mov  si,offset ecb_spx_tr
mov  pbl_spx_transmit[30],0
mov  pbl_spx_transmit[31],0
call SPX_Establish_Connection

mov  bp,offset error_11h
mov  si,offset ecb_spx_tr
call waitings

cmp  exit_flag,1
jne  ready4
jmp  near ptr quit
ready4:

MOV  DX,0602h
MOV  CX,32
MOV  BP,OFFSET spx_br
CALL OUT_date
;--------------------------------------------------------------------
      MOV  DX,0702h 
      MOV  CX,32
      MOV  BP,OFFSET spx_br
      CALL OUT_date
      push cs
      pop  es
      mov  bp,offset begin_transmit
      mov  cx,41
      mov  dx,0802h
      MOV  AX,1301h
      MOV  BX,00ah
      INT  10h
;read_key:
;      mov  ah,0001h
;      int  16h
;      jz   read_key

next:
CLD
MOV  CX,6
MOV  DI,OFFSET ecb[28]
MOV  SI,OFFSET pbl_ipx_resiver_ipx[22]			;заполняем поле
REP  MOVSB					;ImmAddress в ECB[28]
CLD						;широковещательным адресом
MOV  CX,10
MOV  DI,OFFSET pbl_IPX_transmit_ipx[6]
MOV  SI,OFFSET pbl_ipx_resiver_ipx[18]
REP  MOVSB
;--------------------------------------------------------------------
MOV  CX,01h			;посылка пакета IPXу как разрешение
CALL ipx_send_ipx		;начала передачи файла
;--------------------------------------------------------------------
mov  bp,offset error_03h
mov  si,offset ecb
call waitings
cmp  exit_flag,1
jne  ready5
jmp  near ptr quit
ready5:
;--------------------------------------------------------------------
MOV  BX,512				;прием пакета с файлом от ipx
MOV  DX,OFFSET buffer_resiver
MOV  CX,02h
CALL ipx_listen_ipx
;--------------------------------------------------------------------
mov  bp,offset error_04h
mov  si,offset ecb
call waitings
cmp  exit_flag,1
jne  ready6
jmp  near ptr quit
ready6:
;--------------------------------------------------------------------
MOV  AX,WORD PTR pbl_ipx_resiver_ipx[2]
xchg ah,al
SUB  AX,30
MOV  long,AX
;--------------------------------------------------------------------
mov  cx,02h				;посылка пакета SPXa
mov  bx,long
mov  dx,offset buffer_resiver
mov  si,offset ecb_spx_tx
mov  pbl_spx_transmit[30],0
mov  pbl_spx_transmit[31],0
call SPX_Send_Sequenced_packet 

mov  bp,offset error_16h
mov  si,offset ecb_spx_tx
call waitings

call delays
MOV  DX,0902h
MOV  CX,23
MOV  BP,OFFSET retranslation
CALL OUT_date

MOV  Dh,09h
mov  dl,cols
MOV  CX,1
MOV  BP,OFFSET plus
CALL OUT_date
;--------------------------------------------------------------------
MOV  AX,512
CMP  long,AX
JNE  bad
;--------------------------------------------------------------------
inc  cols
JMP  NEAR PTR next
bad:
mov  dx,ipx_socket
call ipx_socket_close   		;номер сокета 6666h
mov  dx,spx_socket
call ipx_socket_close			;номер сокета 4444h
quit:
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
ipx_send_ipx PROC
;--------------------------------------------------------------------
XOR  AX,AX              	     	;подготовка блока ECB
MOV  WORD PTR ECB[6],AX			;для передачи пакета серверу
MOV  WORD PTR ECB[4],AX
mov  ax,ipx_socket
mov  word ptr ecb[10],ax
mov  word ptr pbl_ipx_transmit_ipx[28],ax
;--------------------------------------------------------------------
MOV  WORD PTR ECB[34],CX		;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  WORD PTR ecb[38],CS		;поле Adress 1 сегмент
MOV  WORD PTR ecb[36],OFFSET pbl_IPX_transmit_ipx;поле Adress 1 смещение
MOV  WORD PTR ecb[40],30		;поле SIZE 1
;--------------------------------------------------------------------
MOV  WORD PTR ecb[44],CS		;поле Adress 2 сегмент
MOV  WORD PTR ecb[42],DX        	;поле Adress 2 смещение
MOV  WORD PTR ecb[46],BX  		;поле SIZE 2
;-----------------------		;подготовка IPX заголовка
MOV  pbl_IPX_transmit_ipx[5],4		;тип пакета
;-------------------------------	;заполнение поля 
MOV  AX,7676h                           ;destsocket в заголовке IPX
MOV  WORD PTR pbl_IPX_transmit_ipx[16],AX
cld 
mov  si,offset pbl_ipx_transmit_ipx[16]
mov  di,offset pbl_ipx_transmit_spx
mov  cx,10
rep  movsb
;--------------------------------------------------------------------
MOV  BX,IPXSendPacket
MOV  SI,OFFSET ECB
CALL [API_IPX]
RET
ipx_send_ipx ENDP
;-------------------------------------------------
ipx_listen_ipx PROC
pusha 
XOR  AX,AX
MOV  WORD PTR ECB[6],AX
MOV  WORD PTR ECB[4],AX
mov  ax,ipx_socket
mov  word ptr ecb[10],ax
;--------------------------------------------------------------------
MOV  WORD PTR ECB[34],CX  		;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  WORD PTR ecb[36],OFFSET pbl_ipx_resiver_ipx;поле Adress сегмент
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
popa
RET					;----------------------------
ipx_listen_ipx ENDP			
SPX_Establish_Connection proc
call load_ecb
mov  al,10h
mov  ah,0ffh
mov  bx,SPXEstablishConnection
call [API_IPX]
mov  source_chanell,dx
ret
SPX_Establish_Connection endp
SPX_Terminate_Connection proc
call load_ecb
mov  dx,source_chanell
mov  bx,SPXTerminateConnection
call [API_IPX]
ret
SPX_Terminate_Connection endp
SPX_Send_Sequenced_Packet proc
call load_ecb
mov  dx,source_chanell
mov  bx,SPXSendSequencedPacket
call [API_IPX]
ret
SPX_Send_Sequenced_Packet endp
;--------------------------------------------------------------------
load_ecb proc
XOR  AX,AX
MOV  si[6],AX
MOV  si[4],AX
mov  ax,SPX_socket
mov  si[10],ax
mov  word ptr pbl_spx_transmit[28],ax
mov  ax,5858h
mov  word ptr pbl_spx_transmit[16],ax
mov  word ptr pbl_spx_transmit[5],5
mov  ax,source_chanell
mov  word ptr pbl_spx_transmit[34],ax
mov  ax,dest_chanell
mov  word ptr pbl_spx_transmit[32],ax
;--------------------------------------------------------------------
MOV  si[34],CX  	;Заполнение поля FragmentCnt в ЕСВ
;--------------------------------------------------------------------
MOV  si[36],OFFSET pbl_spx_transmit	;поле Adress сегмент
MOV  si[38],CS
mov  ax,42
MOV  si[40],ax		;поле SIZE
;--------------------------------------------------------------------
MOV  si[42],DX		;поле Adress сегмент
MOV  si[44],CS
MOV  si[46],BX		;поле SIZE
push si
;--------------------------------------------------------------------
CLD
MOV  CX,6
MOV  DI,OFFSET si[28]
MOV  SI,OFFSET pbl_ipx_resiver_ipx[22]		;заполняем поле
REP  MOVSB					;ImmAddress в ECB[28]
cld
MOV  CX,10
MOV  DI,OFFSET pbl_spx_transmit[6]
MOV  SI,OFFSET pbl_ipx_resiver_spx[18]
REP  MOVSB
cld
MOV  CX,10
MOV  DI,OFFSET pbl_spx_transmit[18]
MOV  SI,OFFSET pbl_ipx_transmit_spx[18]
REP  MOVSB
;--------------------------------------------------------------------
pop  si
ret
load_ecb endp
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
ret
SPX_listen_for_sequenced_packet endp
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

push es
      xor  ax,ax
      mov  es,ax
      mov  al,es:[417h]
pop  es
      cmp  al,5
Jne   waitings1		;ожидание прихода пакета
mov   exit_flag,1
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
	mov  dx,01302h
	mov  cx,22
	call out_date
	mov  bp,offset info
	mov  dx,01402h
	mov  cx,47
	call out_date
        mov  bx,max_channell
        call bin_hex_ascii
	mov  bp,offset hex
	mov  dx,01423h
	mov  cx,4
	call out_date
	Mov  bx,free_channell
        call bin_hex_ascii
	mov  bp,offset hex
	mov  dx,01432h
	mov  cx,4
	call out_date
	mov  bp,offset version
	mov  dx,01502h
	mov  cx,19
	call out_date
        Mov  bx,nversion
        call bin_hex_ascii
	mov  bp,offset hex
	mov  dx,01516h
	mov  cx,4
	call out_date
	clc
	ret
	bads:
	mov  bp,offset spx_unload
	mov  dx,01302h
	mov  cx,25
	call out_date
        stc
        ret	
	spx_check endp
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