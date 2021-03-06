default rel

global Printf, CPrintf

%include 'Constant.h'

extern Strlen, PrintStr, PrintStrN, itoa, itoa10, ItoaBuf

;##############################################
; Printf Buffer of len BUF_LEN bytes
;##############################################

section .bss

printBuf	resb BUF_LEN		; buffer for output

%macro CheckOverflow 0
	cmp rdi, printBuf + BUF_LEN - 1	; if >= BUF_LEN - 1 written
	jbe .noFlush %+ __LINE__

	call FlushBuf			; Flush buffer

.noFlush %+ __LINE__:
%endmacro

section .text

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
	CheckOverflow
	
        lodsb                           ; copy 1 byte to AL
        cmp al, EOL                     ; check if byte is 00h
        je  .Fin
        stosb                           ; [DI] = AL 

        jmp .CpyByte

.Fin:
        mov byte [rdi], EOL             ; ENDL symbol
        ret

;==============================================
; Printf made to be run from C with respect
; to fastcall x86_64 Unix conventions.
;
; Expects:
; 	rdi - Format string
; 	ARGS: rsi, rdx, rcx, r8, r9, \
;	      Stack (Cdecl)
;
;==============================================

CPrintf:
	pop r10				; save return addr

	push r9 			;
	push r8 			;
	push rcx			;
	push rdx			;
	push rsi			;
	push rdi 			; push args

	push r10

	push rbp			; stack frame
	mov  rbp, rsp

	call Printf

	pop rbp 			; pop old rbp
	pop r10 		 	; pop ret addr
	
	add rsp, 48
	
	push r10 			; push ret addr

	ret

;==============================================
; Prints a string with respect to the format
; string. Similar to C printf function
;
; Expects: (Cdecl)
; 	printBuf - buffer to print into before
; 		   writing to screen
; 	Stack    - Format str, arguments
;
; Returns:
; 	0
;
; Destr:
; 	Everything
;==============================================

Printf:
	mov rsi, [rbp + 16] 		; rsi - format str
	
	mov rdi, printBuf		; rdi - buffer iterator
	mov rbx, 0			; rbx - argument iterator

.loop:
	xor rax, rax
	lodsb 				; load next byte

	cmp al, '%' 			; if (*Msg == '%')
	je  .percent			; 	process the % symbol
					; else
	cmp al, EOL 			; if str ended
	je  .end 			; 	end the program
					; else
	mov [rdi], al	 		; 	copy from format string into buffer
	inc rdi				; 	increment current string length
	CheckOverflow			; 	check if buffer is overflowed
	jmp .loop			; process next char

.percent:
	xor rax, rax
	lodsb 				; load next byte after %
	
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
	mov rsi, [rbp + rbx * 8 + 16] 	; push next argument = string ptr

	call CpyToBuf			; copy arg string to buffer

	pop rsi

	jmp .symEnd
	
.symC: 					; %c = print char
	inc rbx				; inc arg counter
	mov ax, [rbp + rbx * 8 + 16] 	; rsi = &char arg

	stosb				; print symbol to buffer

	CheckOverflow

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
	mov rdx, [rbp + rbx * 8 + 16] 	; rdx = value to print

	push rdi			; save old rdi
	mov rdi, ItoaBuf 		; rdi = temp buffer

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
	pop rdi				; rdi = free space in buf
	
	push rsi 			; rsi = ItoaBuf
	mov rsi, ItoaBuf 		; copy from ItoaBuf to PrintBuf
	call CpyToBuf
	
	pop rsi

	jmp .symEnd

.dblPercent:
	stosb 				; print % to buffer
	CheckOverflow
	
	jmp .symEnd

.otherSym:
	mov byte [rdi], '%'		; print % sign
	inc rdi 			; increment buff ptr
	CheckOverflow
	
	jmp .symEnd
	
.symEnd:
	jmp  .loop

.end:
	call FlushBuf			; print the remains

	xor rax, rax 			; ret val = 0
	ret
