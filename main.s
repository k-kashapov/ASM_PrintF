section .text

global _start

%include 'Constant.h'

extern Printf

;##############################################
; Main
;##############################################

_start:
	push 1337
	push TmpStr
	push 3802
	push Chr
	push Msg
	
	call Printf

	mov rax, 0x3c	; exit (rdi)
	xor rdi, rdi
	syscall
	
section .data
	
Msg	db '%% <- this is percent', 10, 'r = |%c|', 10, '3802 = 0x|%x|', 10, 'JOJO = |%s|', 10,'1337 = |%d|', EOL
Chr	db 'r'
TmpStr  db 'JOJO', EOL
