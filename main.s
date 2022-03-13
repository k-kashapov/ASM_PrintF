section .text

global _start

%include 'Constant.h'

extern Printf, CPrintf

;##############################################
; Main
;##############################################

_start:
	mov r8, 1337
	mov rcx, TmpStr
	mov rdx, 3802
	mov rsi, Chr
	mov rdi, Msg

	mov rsi, Msg
	
	call CPrintf

	mov rax, 0x3c	; exit (rdi)
	xor rdi, rdi
	syscall
	
section .data
	
Msg	db '%% <- this is percent', 10, 'r = |%c|', 10, '3802 = 0x|%x|', 10, 'JOJO = |%s|', 10,'1337 = |%d|', EOL
Chr	db 'r'
TmpStr  db 'JOJO', EOL
