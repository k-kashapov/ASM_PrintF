section .text

global Printf

%include 'Constant.h'

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
	push rbp			; stack frame
	mov  rbp, rsp

	mov rsi, [rsp + 16]		; load format string to rsi
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
	cmp rdx, 00 			; if no chars are to be printed:
	je  .noPrint			; 	don't print
					; else
	call PrintStrN			; 	print the whole str before % sym
	add  rsi, rdx			; 	move rsi to the pos before the %	
	
.noPrint:

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

[section .data]

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

__SECT__ 				; return to the previous section type

;##############################################
; Symbols processing
;##############################################

.symS: 					; %s = print string
        inc rbx				; increment argument counter
	push qword [rsp + rbx * 8 + 8] 	; push next argument = string ptr

	call PrintStr 			; Print the string
	mov  rdx, 2			; '%_': 2 bytes processed

	jmp .symEnd
	
.symC: 					; %c = print char
	push rsi			; save rsi

	inc rbx				; inc arg counter
	mov rsi, [rsp + rbx * 8 + 16] 	; rsi = &char arg
	
	mov rax, 0x01 			; write (rdi, rsi, rdx)
	mov rdi, 0x01 			; stdout
	mov rdx, 1 			; write 1 byte
	syscall

	pop rsi				; restore rsi

	mov rdx, 2			; '%_': 2 bytes processed

	jmp .symEnd
	
.symD:
	mov cl, 0 			; base 10 indicator
	jmp .PrintNum

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
	inc rbx
	mov rdi, [rsp + rbx * 8 + 8] 	; rdi = value to print

        push rsi

	mov rsi, ItoaBuf		; rsi = &ItoaBuf

	cmp cl, 00 			; if base indicator in not 00
	jne .toBase2n 			; 	base = 2^n
					; else
					; 	base = 10
.toBase10:
	call itoa10 			; num to string, base 10
	jmp  .translated

.toBase2n:
	call itoa 			; number to string, base 2^n

.translated:
	push rsi			; push rsi as PrintStr arg
	call PrintStr
	
       	pop rsi
       	mov rdx, 2 			; 2 symbols have been processed

	jmp .symEnd

.dblPercent:
	mov rdx, 1 		; print 1 percet sym
	call PrintStrN

	add rdx, 1 		; step over the next % sign
	jmp .symEnd

.otherSym:
	call PrintStrN		; print the whole str including '%_'
	
.symEnd:
	add rsi, rdx		; move string start to the new position
	
	mov rdi, rsi		; update string iterator
	xor rdx, rdx		; reset string len counter

	jmp  .loop

.end:
	call PrintStrN		; print the remains

	pop rbp

	ret
