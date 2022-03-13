all: 		runFromC

runFromC: 	obj main.cpp
		gcc main.cpp obj/*.o -o RunFromC.exe -no-pie

runFromASM: 	obj obj/main.o
		ld -s obj/Printf.o obj/StrFunc.o obj/main.o  -m elf_x86_64 -o Printf.exe

main.o: 	main.s
		nasm main.s -l Listing.lst -f elf64 -i include -o obj/main.o

Printf.o: 	src/Printf.s
		nasm src/Printf.s -l Listing.lst -f elf64 -i include -o obj/Printf.o

StrFunc.o:	src/StrFunc.s
		nasm src/StrFunc.s -l Listing.lst -f elf64 -i include -o obj/StrFunc.o

obj: 		Printf.o StrFunc.o
