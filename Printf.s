section .text

global _start

EOL	equ 00	; end of line symbol

extern Strlen, PrintStr, PrintStrN, itoa, itoa10, ItoaBuf
	
;==============================================
; Prints a string with respect to the format
; string. Similar to C printf function
;
; Expects: (Cdecl)
; 	Format string ptr, args...
;
; Returns:
;
;==============================================

Printf:
	mov rsi, [rsp + 8]		; load format string to rsi
	mov rdi, rsi			; rdi - string iterator
	xor rdx, rdx			; rdx - string lenth counter
	mov rbx, 1			; rbx - argument iterator

.loop:
	xor rax, rax
	mov al, [rdi] 			; load byte symbols into al
	inc rdi 			; move to the next symbol

	cmp al, '%' 			; if (*Msg == '%')
	je  .percent			; 	process the % symbol
					; else
	cmp al, EOL 			; if str ended
	je  .end 			; 	end the program
					; else
	inc rdx				; 	increment current string length
	jmp .loop			; process next char

.percent:
	xor rax, rax
	mov al, [rdi] 			; load next char after % into al

	cmp al, '%' 			; special case when %% is entered
	je  .dblPercent

	cmp al, 'x' 			; if char > x
	ja  .otherSym 			; print it
		
	sub al, 'b' 			; rax = letter offset from 'b'
	jb  .otherSym			; if char is not [b-x], print it

	mov rax, [.specSym + rax * 8] 	; load jmp label from jump table
	jmp rax				; jump at the respective char value

;##############################################
; Jump table for symbols: b, c, d, o, s
;##############################################

.specSym:
	dq .symB
	dq .symC
	dq .symD
	times ('n' - 'd') dq .otherSym	; (C) Technique successfuly stolen from d3phys
        dq .symO
        times ('r' - 'o') dq .otherSym
        dq .symS
        times ('w' - 's') dq .otherSym
        dq .symX

;##############################################
; Symbols processing
;##############################################

.symS: 					; %s = print string
	call PrintStrN			; print the whole str before % sym
	add rdx, 2

        inc rbx				; increment argument counter
	push qword [rsp + rbx * 8] 	; push next argument = string ptr

	call PrintStr 			; Print the string

	jmp .symEnd
	
.symC: 					; %c = print char
	call PrintStrN			; print the whole str before % sym
	add rdx, 2
	
	push rsi			; save rsi

	inc rbx				; inc arg counter
	mov rsi, [rsp + rbx * 8 + 8] 	; rsi = &char arg
	
	push rdx			; save rdx
	
	mov rax, 0x01 			; write (rdi, rsi, rdx)
	mov rdi, 0x01 			; stdout
	mov rdx, 1 			; write 1 byte
	syscall

	pop rdx				; restore rdx
	pop rsi				; restore rsi

	jmp .symEnd
	
.symD:
	call PrintStrN
	add rdx, 2

	inc rbx 			; inc arg counter
	mov rdi, [rsp + rbx * 8] 	; load next arg

	push rbx
	push rsi
	push rdx

	mov rsi, ItoaBuf		; rsi = 64 byte buffer
	call itoa10			; call itoa base 10

	push rsi			; push buffer as PrintStr arg
	call PrintStr

	pop rdx
	pop rsi
	pop rbx
	jmp .symEnd

.symB:
	mov cl, 1 			; base = 2^1 = 2
	jmp .PrintNum
	
.symO: 	
	mov cl, 3 			; base = 2^3 = 8
	jmp .PrintNum
	
.symX:
	mov cl, 4			; base = 2^4 = 16
	jmp .PrintNum

.PrintNum:
	call PrintStrN			; print out string before %
	add rdx, 2			; step over %_

	inc rbx
	mov rdi, [rsp + rbx * 8] 	; rdi = value to print

        push rsi
	push rbx
        
	mov rsi, ItoaBuf		; rsi = &ItoaBuf
	
	call itoa

	push rsi			; push rsi as PrintStr arg
	call PrintStr
	
       	pop rbx
       	pop rsi

	jmp .symEnd

.dblPercent:
	add rdx, 1 		; print whole string and 1 percet sym
	call PrintStrN

	add rdx, 1 		; step over the next % sign
	jmp .symEnd

.otherSym:
	add rdx, 2		; step over '%_'
	call PrintStrN		; print the whole str including '%_'
	
.symEnd:
	add rsi, rdx		; move string start to the new position
	
	mov rdi, rsi		; update string iterator
	xor rdx, rdx		; reset string len counter

	jmp  .loop

.end:
	call PrintStrN		; print the remains

	ret

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
