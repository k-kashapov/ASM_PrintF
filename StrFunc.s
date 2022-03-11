section .text

EOL	equ 00h

global Strlen, PrintStr, PrintStrN

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
