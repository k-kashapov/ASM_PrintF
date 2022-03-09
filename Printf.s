section .text

global _start

EOL	equ 00

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
; 	rdi
;==============================================

PrintStrN:
	push rax
	
    	mov rax, 0x01   	; write (rdi, rsi, rdx)
	mov rdi, 1		; rdi = stdout
	syscall			; writes string to the stdout

	pop rax
	
	ret

;==============================================
; Prints a string into stdout. String must
; end with EOL symbol.
; 
; Expects:
; 	String ptr
; Destr:
; 	rax, rsi
;==============================================

PrintStr:
	mov [rsp - 8], rsi	; save rsi as local var
	mov rax, [rsp + 8] 	; push string ptr to stack
	push rax
	call StrLen		; get string length

	mov rsi, rax
	call PrintStrN		; PrintStrN (rsi = str ptr, rdx = str len)
	
	mov rsi, [rsp - 8] 	; reset rsi value
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
	mov rsi, [rsp + 8]	; load format string to rsi
	mov rdi, rsi		; rdi - string iterator
	xor rdx, rdx		; rdx - string lenth counter
	mov rbx, 1		; rbx - argument iterator

.loop:
	xor rax, rax
	mov al, [rdi] 		; load byte symbols into al
	inc rdi 		; move to the next symbol

	cmp al, '%' 		; if (*Msg == '%')
	je  .percent		; 	print the whole string before the %
				; else
	cmp al, EOL 		; if str ended
	je  .end 		; 	end the program
				; else
	inc rdx			; 	increment current string length
	jmp .loop		; process next char

.percent:
	xor rax, rax
	mov al, [rdi] 		; load next char after %
	
	sub al, 'b' 		; rax = letter offset from 'b'

	mov rax, [.specSym + rax * 8] 	; jump at the respective char value
	jmp rax
	
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
        dq .symX

.symS:
	call PrintStrN

        inc rbx
        mov rax, [rsp + rbx * 8]

	push rax
	call PrintStr

	jmp .symEnd
	
.symB:
        mov rax, 1
.symC:
        mov rax, 2
.symD:
        mov rax, 3
.symO:
        mov rax, 4
.symX:
        mov rax, 6

.otherSym:
	call PrintStrN

.symEnd:
	add rsi, rdx		; move string start to the new position
	
	mov rdi, rsi		; update string iterator
	xor rdx, rdx		; reset string len counter

	jmp  .loop

.end:
	call PrintStr	; print the remains

	ret

;##############################################
; Main
;##############################################

_start:
	push Msg1
	push Msg
	
	call Printf
		
	; mov  rsi, Msg
	; call PrintStr

	mov rax, 0x3c	; exit (rdi)
	xor rdi, rdi
	syscall

section .data

Msg	db 'Hello %s world', 10, EOL
Msg1	db 'JOJO', EOL
