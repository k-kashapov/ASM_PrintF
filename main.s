section .text

global _start

%include 'Constant.h'

extern Printf

;##############################################
; Main
;##############################################

_start:
	push 3802
	push Msg
	
	call Printf

	mov rax, 0x3c	; exit (rdi)
	xor rdi, rdi
	syscall
	
section .data
	
Msg	db '3802 = 0x%x', 10, EOL
Chr	db 'r'
