;-------------------------------------------------------------------------
IPXsocket                            equ 6666h
IPXsocket_server                     equ 7777h
SPXsocket                            equ 4444h
SPXsocket_server                     equ 5555h
IPXGetInternetworkAddress            EQU 09h
IPXListen                            EQU 04h
IPXSendPacket                        EQU 03h
IPXOpenSocket                        EQU 00h
IPXCloseSocket                       EQU 01h
IPXRelinquishControl                 EQU 0ah
SEARCH_IPX                           EQU 7a00h
SPXCheckInstallation                 equ 10h
SPXListenForConnection               equ 12h
SPXEstablishConnection               equ 11h
SPXListenForSequencedPacket          equ 17h
SPXSendSequencedPacket               equ 16h
SPXTerminateConnection               equ 13h
;-------------------------------------------------------------------------
;cseg segment
;OUT_date     PROC
;      PUSH ES
;      PUSH CS
;      POP  ES
;      MOV  AX,1301h
 ;     MOV  BX,00fh
;      INT  10h
;      POP  ES
;      RET
;OUT_date     ENDP                 
;cseg ends
