section .text

%include 'Constant.h'

global Strlen, PrintStr, PrintStrN, itoa, itoa10, ItoaBuf

;==============================================
; Counts string length. String must end with
; EOL symbol
; Expects:
; 	rsi - String
; Returns:
; 	rcx - String length
; Destr:
; 	rsi
;==============================================

StrLen:	
        xor rcx, rcx
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

;##############################################
; Data buffers
;##############################################

section .data

HEX	db '0123456789ABCDEF'

section .bss

ItoaBuf resb 64

section .text

;==============================================
; Converts integer value into a string, base 2^n
; Expects:
;       cl  - Base = 2^cl
;       rdx - Integer value
;       rdi - Buffer to write str into
; Returns:
;       rdi - Result string
; 	r8  - Number of bytes printed
; Destr:
; 	rax, r10, rcx
;==============================================

itoa:	
        call CountBytes
        
        add rdi, rax                    ; save space for elder bits in buff: _ _ _ rdi: _

        movzx rax, cl			; rax = cl
        mov r8, rax 			; save printed len to r8
	dec r8 				; number of bytes excluding the last EOL symbol

        mov byte [rdi], EOL             ; put EOL as last byte: _ _ _ _ $
        dec rdi                         ; _ _ _ rdi: _ $

        mov r10, 01b                    ; mask = 0..01b
        shl r10, cl                     ; mask = 0..010..0b
        dec r10                         ; mask = 0..01..1b

.BitLoop:
        mov rax, r10

        and rax, rdx                    ; apply mask to rdx
        shr rdx, cl                     ; cut off masked bits: 01010011 -> 001010|011

        mov al, [rax + HEX]
        mov [rdi], al

.CmpZero:
        dec rdi                        	; moving backwards: _ _ rdi: _ 0 1 0 $
        cmp rdx, 00h                    ; check if the whole value has been printed
        ja  .BitLoop

	inc rdi				; rdi must point to the first byte of buf

        ret

;==============================================
; Counts amount of bytes needed to save the
; number into buffer
;
; Expects:
;       rdx - Value
;       cl - Base
; Returns:
;       rax = ch - amount of bytes needed
; Destr:
; 	None
;==============================================

CountBytes:
	xor rax, rax
        mov rax, rdx	; save value in r10 to count symbols in it
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
;       rdx - Integer value
;       rdi - Buffer to write into
; Returns:
;       r8  - Printed bytes num
; Destr:
;       rdx, r10, r9
;==============================================

itoa10:
	xor r8, r8		; r8 = bytes counter
	mov r9, rdx 		; from now on, value is stored in r9
        mov rax, rdx		; save value to rax
        mov r10, 10

.CntBytes:              	; skips, bytes that are required to save the value
        xor rdx, rdx		; reset remaining
        div r10                 ; rax = rax / 10; rdx = rax % 10

        inc rdi
        inc r8
        cmp rax, 0000h
        ja .CntBytes

        mov rax, r9           	; reset value
        
        mov byte [rdi], EOL
        dec rdi

.Print:
        xor rdx, rdx
        div r10                 ; rax = rax / 10; rdx = rax % 10
        
        add dl, '0'           	; to ASCII
        mov [rdi], dl
        dec rdi

        cmp rax, 00h
        ja .Print
				; rdi = &buffer - 1
	inc rdi			; rdi = &buffer

        ret
