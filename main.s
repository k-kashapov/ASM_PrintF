section .text

global _start

%include 'Constant.h'

extern Printf

;##############################################
; Main
;##############################################

_start:
	push 13
	push Msg
	
	call Printf

	mov rax, 0x3c	; exit (rdi)
	xor rdi, rdi
	syscall
	
section .data
	
Msg	db 'Hello %x wo%%oohooo %w world', 10, EOL
Chr	db 'd'
