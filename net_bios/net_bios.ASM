.286
cseg SEGMENT
ASSUME CS:cseg,DS:cseg
ORG 100h
start:JMP begin
;--------------------------------------------------------------------
ncb                     DB 64 DUP(0)
networknamenumber       DB 0
;--------------------------------------------------------------------
group_NAME 		DB                    '  Sergey Tristan'
load_nb			DB 'Протокол  NetBios  установлен.'
unload_nb     		DB 'Протокол  NetBios  неустановлен.'
error_30h               DB 'Функция 30h поля CCode и FinalCCode'
error_31h               DB 'Функция 31h поля CCode и FinalCCode'
error_20h               DB 'Функция 20h поля CCode и FinalCCode'
;--------------------------------------------------------------------
wait        		DB 0
hex                     DB 4 DUP(48)
flag                    DB 0
handle                  DW 0
buffer_transmit         DB 512 DUP(0)
lengh			DW 0
;--------------------------------------------------------------------
begin:
MOV  AX,0600h
MOV  DX,1950h
MOV  CX,0h
MOV  BX,0700h
INT  10h
MOV  DI,0
CALL load_netbios
PUSH CS
POP  ES
readkey:
MOV  AH,01h
INT  21h
MOV  OFFSET buffer_transmit[DI],AL
INC  DI
CMP  AL,27
JNE  readkey
DEC  DI
MOV  lengh,DI
MOV  wait,0
MOV  DX,OFFSET group_NAME
MOV  SI,OFFSET ncb
CALL nb_addgroupname
MOV  BP,OFFSET error_30h
MOV  BH,ncb[1]
MOV  BL,ncb[49]
MOV  DH,03
CALL error_code
;--------------------------------------------------------------------
PUSH SI
CLD  
MOV  CX,16
MOV  DI,OFFSET ncb[10]
MOV  SI,OFFSET group_name
REP  MOVSB
MOV  SI,OFFSET ncb
MOV  wait,0
MOV  CX,lengh
MOV  DX,OFFSET buffer_transmit
CALL nb_senddatagram
MOV  BP,OFFSET error_20h
MOV  BH,ncb[1]
MOV  BL,ncb[49]
MOV  DH,06  
CALL error_code
;--------------------------------------------------------------------
MOV  wait,0
MOV  DX,OFFSET group_NAME
MOV  SI,OFFSET ncb
CALL nb_deletename
MOV  BP,OFFSET error_31h
MOV  BH,ncb[1]
MOV  BL,ncb[49]
MOV  DH,07
CALL error_code
;--------------------------------------------------------------------
MOV  AH,4ch
INT  21h
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
load_netbios PROC
MOV  AH,35h
MOV  AL,5ch
INT  21h
MOV  AX,0000h
MOV  BX,ES
CMP  BX,AX
JE   bad_NB
MOV  DX,0202h
MOV  CX,30
MOV  BP,OFFSET load_NB
CALL OUT_date
CLC
RET
bad_NB:
MOV  DX,0202h
MOV  CX,32
MOV  BP,OFFSET unload_NB
CALL OUT_date
STC
RET
load_netbios ENDP
NB_addgroupname PROC
CMP  wait,0				;параметры: в DX адрес перемен
JNE  nb_agn_1				;ной содержащей имя для добавления
MOV  AH,030h
MOV  SI[0],AH				;в WAIT флаг ждать или нет
JMP  nb_agn_2				;0 с ожидаием - 1 без ожидания
nb_agn_1:				;в SI адрес NCB
MOV  AH,0b0h
MOV  SI[0],AH
nb_agn_2:
PUSH SI
CLD
MOV  CX,16
MOV  AX,OFFSET SI
ADD  AX,26
MOV  DI,AX
MOV  SI,DX
REP  MOVSB
POP  SI
MOV  AX,0
MOV  WORD PTR SI[44],AX
MOV  WORD PTR SI[46],AX
MOV  AH,0
MOV  SI[48],AH
MOV  BX,SI
MOV  AH,04h
MOV  AL,00h
INT  5ch
MOV  AL,SI[3]
MOV  networknamenumber,AL
RET
NB_addgroupname ENDP
nb_deletename PROC
CMP  wait,0				;параметры: в SI адрес перемен
JNE  nb_dn_1
MOV  AH,031h				;ной содержащей имя для удаления
MOV  SI[0],AH	 			;в WAIT флаг ждать или нет
JMP  nb_dn_2				;0 с ожидаием - 1 без ожидания
nb_dn_1:
MOV  AH,0b1h
MOV  SI[0],AH
nb_dn_2:
PUSH SI
CLD  
MOV  CX,16
MOV  DI,OFFSET SI[26]
MOV  SI,DX
REP  MOVSB
POP  SI
MOV  AX,0
MOV  WORD PTR SI[44],AX
MOV  WORD PTR SI[46],AX
MOV  SI[48],AH
MOV  BX,OFFSET SI
MOV  AH,04h
MOV  AL,00h
INT  5ch
RET
nb_deletename ENDP
nb_senddatagram PROC
CMP  wait,0				;параметры: в SI адрес перемен
JNE  nb_sn_1
MOV  AH,020h				;ной содержащей имя для удаления
MOV  SI[0],AH				;в WAIT флаг ждать или нет
JMP  nb_sn_2				;0 с ожидаием - 1 без ожидания
nb_sn_1:
MOV  AH,0a0h
MOV  SI[0],AH
nb_sn_2:
MOV  AL,networknamenumber
MOV  SI[3],AL
MOV  WORD PTR SI[4],DX
MOV  WORD PTR SI[6],CS
MOV  CX,lengh
MOV  WORD PTR SI[8],CX
MOV  AX,0
MOV  WORD PTR SI[44],AX
MOV  WORD PTR SI[46],AX
MOV  SI[48],AL
MOV  BX,OFFSET SI
MOV  AH,04h
MOV  AL,00h
INT  5ch
RET
nb_senddatagram ENDP
bin_hex_ascii PROC
      PUSHA
      PUSH CX
      PUSH DI
      MOV  DI,0
agn:  MOV  hex[DI],48
      INC  DI
      CMP  DI,3
      JNE  agn
      MOV  flag,0 
      MOV  AX,BX
      MOV  CX,10h
      MOV  DI,3
mcb11:XOR  DX,DX
      DIV  CX
      CMP  AX,0fh
      JG   mcb12
      MOV  flag,1
mcb12:CMP  DX,9
      JG   mcb13
      ADD  DX,48
      MOV  hex[DI],DL
      JMP  mcb14
mcb13:ADD  DX,55
      MOV  hex[DI],DL
mcb14:DEC  DI     
      CMP  flag,01
      JE   mcb15
      JMP  mcb11
mcb15:CMP  AX,9
      JG   mcb16
      ADD  AX,48
      MOV  hex[DI],AL
      JMP  mcb17
mcb16:ADD  AX,55
      MOV  hex[DI],AL         
mcb17:POP  DI
      POP  CX
      POPA
      RET
bin_hex_ascii ENDP
error_code PROC
CALL bin_hex_ascii
MOV  CX,35
MOV  DL,02h
CALL OUT_date
MOV  CX,4
MOV  DL,27h
MOV  BP,OFFSET hex
CALL OUT_date
RET
error_code ENDP
cseg ENDS
END  start