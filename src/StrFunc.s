section .text

%include 'Constant.h'

global Strlen, PrintStr, PrintStrN, itoa, itoa10, ItoaBuf

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
; 	rax, r10, rcx
;==============================================

itoa:	
        call CountBytes
        
        add rsi, rax                    ; save space for elder bits in buff: _ _ _ rdi: _
        
        movzx rax, cl			; rax = cl

        mov byte [rsi], EOL             ; put $ as last byte: _ _ _ _ $
        dec rsi                         ; _ _ _ rdi: _ $

        mov r10, 01b                    ; mask = 0..01b
        shl r10, cl                     ; mask = 0..010..0b
        dec r10                         ; mask = 0..01..1b

.BitLoop:
        mov rax, r10

        and rax, rdi                    ; apply mask to rdx
        shr rdi, cl                     ; cut off masked bits: 01010011 -> 001010|011

        mov al, [rax + HEX]
        mov [rsi], al

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
        mov rax, rdi	; save value in r10 to count symbols in it
        xor ch, ch

.Loop:
        inc ch  	; bytes counter
        shr rax, cl     ; rax >> cl
        jnz .Loop

	xor rax, rax
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
;       rdx, rcx, r10
;==============================================

itoa10:
        mov rax, rdi		; save value to rax
        mov r10, 10

.CntBytes:              	; skips, bytes that are required to save the value
        xor rdx, rdx		; reset remaining
        div r10                 ; rax = rax / 10; rdx = rax % 10

        inc rsi
        cmp rax, 0000h
        ja .CntBytes

        mov rax, rdi           	; reset value
        
        mov byte [rsi], EOL
        dec rsi

.Print:
        xor rdx, rdx
        div r10                 ; rax = rax / 10; rdx = rax % 10
        
        add dl, '0'           	; to ASCII
        mov [rsi], dl
        dec rsi

        cmp rax, 00h
        ja .Print

	inc rsi

        ret
