global Printf

%include 'Constant.h'

extern Strlen, PrintStr, PrintStrN, itoa, itoa10, ItoaBuf

;##############################################
; Printf Buffer of len BUF_LEN bytes
;##############################################

section .bss

printBuf	resb BUF_LEN	; buffer for output

section .text

;==============================================
; Checks if buffer is about to be overflowed.
; Calls FlushBuf if it is.
; Expects:
; 	BUF_LEN - const, buffer length
; 	rdi     - pointer to some place in buf
;==============================================

CheckOverflow:
	cmp rdi, printBuf + BUF_LEN - 1	; if >= BUF_LEN - 1 written
	jbe .noFlush

	call FlushBuf			; Flush buffer

.noFlush:
	ret

;==============================================
; Flushes printf buffer. Returns rdi to the
; buffer start
; Expects:
; 	printBuf - buffer to flush
; 	rdi      - position of the last printed
; 		   symbol in buffer
; Returns:
; 	rdi = printBuf
; Destr:
; 	None
;==============================================

FlushBuf:
	push rsi
	push rdx
	
	mov rsi, printBuf	; buffer ptr
	
	mov rdx, rdi 		; length to print
	sub rdx, printBuf 	; 
	
	call PrintStrN

	pop rdx
	pop rsi

	mov rdi, printBuf	; reset buffer
	
	ret

;==============================================
; Copies bytes of string into buffer. Puts
; ENDL (00h) symbol at the end of the str.
; Flushes buffer if it's overwlowed.
; Expects:
;       rdi - Buffer of length >= n + 1
;       rsi - String address
; Returns:
; 	None
; Destr:
;       rax
;==============================================

CpyToBuf:

.CpyByte:
	call CheckOverflow
	
        lodsb                           ; copy 1 byte to AL
        cmp al, EOL                     ; check if byte is 00h
        je  .Fin
        stosb                           ; [DI] = AL 

        jmp .CpyByte

.Fin:
        mov byte [rdi], EOL              ; ENDL symbol
        ret

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

	mov rsi, [rbp + 16]		; load format string to rsi
	mov rdi, printBuf		; rdi - buffer iterator
	mov rbx, 1			; rbx - argument iterator

.loop:
	xor rax, rax
	mov al, [rsi] 			; load byte symbols into al
	inc rsi 			; move to the next symbol

	cmp al, '%' 			; if (*Msg == '%')
	je  .percent			; 	process the % symbol
					; else
	cmp al, EOL 			; if str ended
	je  .end 			; 	end the program
					; else
	mov [rdi], al	 		; 	copy from format string into buffer
	call CheckOverflow		; 	check if buffer is overflowed
	inc rdi				; 	increment current string length
	jmp .loop			; process next char

.percent:
	xor rax, rax
	mov al, [rsi] 			; load next char after % into al
	
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

[section .data] 			; (C) Feature by RustamSubkhankulov

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
	push rsi

        inc rbx				; increment argument counter
	mov rsi, [rbp + rbx * 8 + 24] 	; push next argument = string ptr

	call CpyToBuf			; copy arg string to buffer

	pop rsi
	add rsi, 2			; '%_': 2 bytes processed

	jmp .symEnd
	
.symC: 					; %c = print char
	inc rbx				; inc arg counter
	mov ax, [rbp + rbx * 8 + 24] 	; rsi = &char arg

	mov [rdi], al

	call CheckOverflow
	inc rdi 			; 1 byte written to buffer

	add rsi, 2			; '%_': 2 bytes processed

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
	mov rdx, [rbp + rbx * 8 + 8] 	; rdx = value to print

        push rsi

	mov rsi, ItoaBuf		; rsi = &ItoaBuf

	cmp cl, 00 			; if base indicator != 00
	jne .toBase2n 			; 	base = 2^n
					; else
					; 	base = 10
.toBase10:
	call itoa10 			; num to string, base 10
	jmp  .translated

.toBase2n:
	call itoa 			; number to string, base 2^n

.translated:
	add rdi, r8 			; copy translated str to the buffer
	
       	pop rsi
       	add rsi, 2 			; 2 symbols have been processed

	jmp .symEnd

.dblPercent:
	mov [rdi], al 			; print % into buffer
	
	call CheckOverflow
	inc rdi

	inc rsi 			; step over the next % sign
	jmp .symEnd

.otherSym:
	mov byte [rdi], '%'		; print % sign
	call CheckOverflow
	inc rdi

	inc rsi 			; step over the next % sign
	jmp .symEnd
	
.symEnd:
	jmp  .loop

.end:
	call FlushBuf			; print the remains

	pop rbp

	ret
