all: 		exe

Printf.o: 	Printf.s
		nasm Printf.s -l Listing.lst -f elf64

StrFunc.o:	StrFunc.s
		nasm StrFunc.s -l Listing.lst -f elf64

obj: 		Printf.o StrFunc.o

exe: 		Printf.o StrFunc.o
		ld -s Printf.o StrFunc.o -m elf_x86_64 -o Printf.exe
