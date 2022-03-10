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

	mov rsi, ItoaBuf
	call itoa10

	push rsi
	call PrintStr

	pop rdx
	pop rsi
	pop rbx
	jmp .symEnd

.symB:
	call PrintStrN			; print out string before %
	mov cl, 1 			; base = 2^1 = 2
	jmp .PrintNum
	
.symO: 	
	call PrintStrN			; print out string before %
	mov cl, 3 			; base = 2^3 = 8
	jmp .PrintNum
	
.symX:
	call PrintStrN			; print out string before %
	mov cl, 4			; base = 2^4 = 16
	jmp .PrintNum

.PrintNum:
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
; ITOA functions
;##############################################

section .data

HEX	db '0123456789ABCDEF'
ItoaBuf times 64 db 0

section .text

;==============================================
; Converts integer value into a string, base 2^n
; Expects:
;       cl  - Base = 2^cl
;       rdi - Integer value
;       rsi - Buffer to write str into
; Returns:
;       rsi - Result string
; Destr:
; 	rax, rbx, rcx
;==============================================

itoa:	
        call CountBytes
        
        add rsi, rax                    ; save space for elder bits in buff: _ _ _ rdi: _
        
        xor rbx, rbx                    ; rbx = cl
        mov bl, cl

        mov byte [rsi], EOL             ; put $ as last byte: _ _ _ _ $
        dec rsi                         ; _ _ _ rdi: _ $

        mov rax, 01b                    ; mask = 0..01b
        shl rax, cl                     ; mask = 0..010..0b
        dec rax                         ; mask = 0..01..1b

.BitLoop:
        mov rbx, rax

        and rbx, rdi                    ; apply mask to rdx
        shr rdi, cl                     ; cut off masked bits: 01010011 -> 001010|011

        mov bl, [rbx + HEX]
        mov [rsi], bl

.CmpZero:
        dec rsi                        	; moving backwards: _ _ rdi: _ 0 1 0 $
        cmp rdi, 00h                    ; check if the whole value has been printed
        ja  .BitLoop

	inc rsi				; rsi must point it the first byte of buf

        ret

;==============================================
; Counts amount of bytes needed to save the
; number into buffer
;
; Expects:
;       rdi - Value
;       cl - Base
; Returns:
;       rax = ch - amount of bytes needed
; Destr:
; 	ch
;==============================================

CountBytes:
	xor rax, rax
        mov rax, rdi	; save value in ax to count bits in it
        xor ch, ch

.Loop:
        inc ch  	; bytes counter
        shr rax, cl     ; rax >> cl
        jnz .Loop

        mov al, ch

        ret

;==============================================
; Converts integer value into a string, base 10
; Expects:
;       rdi - Integer value
;       rsi - Buffer to write into
; Returns:
;       None
; Destr:
;       rdx, rcx, rbx
;==============================================

itoa10:
        mov rax, rdi		; save value to rcx
        mov rbx, 10

.CntBytes:              	; skips, bytes that are required to save the value
        xor rdx, rdx		; reset remaining
        div rbx                 ; rax = rax / 10; rdx = rax % 10

        inc rsi
        cmp rax, 0000h
        ja .CntBytes

        mov rax, rdi           	; reset value
        
        mov byte [rsi], EOL
        dec rsi

.Print:
        xor rdx, rdx
        div rbx                 ; rax = rax / 10; rdx = rax % 10
        
        add dl, '0'           	; to ASCII
        mov [rsi], dl
        dec rsi

        cmp rax, 00h
        ja .Print

	inc rsi

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

Msg	db 'Hello %d wo%%oohooo %w world', 10, EOL
Chr	db 'd'
