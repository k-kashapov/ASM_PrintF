section .text

global _start

EOL	equ 00	; end of line symbol

;==============================================
; Counts string length. String must end with
; EOL symbol
; Expects:
; 	String ptr
; Returns:
; 	rdx - String length
; Destr:
; 	rsi
;==============================================

StrLen:	
        xor rdx, rdx
        mov rsi, [rsp + 8]

.ChLoop:
        cmp byte [rsi], EOL	; check if line ended
        je  .EOL
        
        inc rdx			; length counter
        inc rsi
        jmp .ChLoop

.EOL:
        ret 8

;==============================================
; Prints a string of fixed width into stdout
;
; Expects:
; 	rsi - String pointer
;	rdx - String len
; Returns:
; 	None
; Destr:
; 	None
;==============================================

PrintStrN:
	push rax
	push rdi
	
    	mov rax, 0x01   ; write (rdi, rsi, rdx)
	mov rdi, 1	; rdi = stdout
	syscall		; writes string to the stdout

	pop rdi
	pop rax
	
	ret

;==============================================
; Prints a string into stdout. String must
; end with EOL symbol.
; 
; Expects:
; 	String ptr
; Destr:
; 	rax
;==============================================

PrintStr:
	push rdx		; save rdx
	push rsi		; save rsi

	mov rax, [rsp + 3 * 8] 	; push string ptr to stack
	push rax
	call StrLen		; get string length

	mov rsi, rax
	call PrintStrN		; PrintStrN (rsi = str ptr, rdx = str len)
	
	pop rsi			; restore rsi
	pop rdx			; restore rdx
	
	ret 8
	
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

	cmp al, 'x' 			; if char > x
	ja  .otherSym 			; print it
		
	sub al, 'b' 			; rax = letter offset from 'b'
	jb  .otherSym			; if char is not [b-x], print it

	mov rax, [.specSym + rax * 8] 	; load jmp label from jump table
	jmp rax				; jump at the respective char value

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
	
.symB:
        mov rax, 1
.symD:
        mov rax, 3
.symO:
        mov rax, 4
.symX:
        mov rax, 6

	jmp .symEnd

;##############################################
; Jump table for symbols: b, c, d, o, s
;##############################################

.specSym:
	dq .symB
	dq .symC
	dq .symD
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .symO
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .symS
        dq .otherSym
        dq .otherSym
        dq .otherSym
        dq .otherSym

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

        dq .symX

;##############################################
; Main
;##############################################

_start:
	push Chr
	push Msg
	
	call Printf

	mov rax, 0x3c	; exit (rdi)
	xor rdi, rdi
	syscall

section .data

Msg	db 'Hello %c wooohooo %w world', 10, EOL
Chr	db 'd'
