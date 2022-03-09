all: 	obj exe

obj: 	Printf.s
	nasm Printf.s -l NasmLst -f elf64

exe: 	Printf.o
	ld -s Printf.o -m elf_x86_64 -o Printf.exe
