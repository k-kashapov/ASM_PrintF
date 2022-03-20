extern "C" int CPrintf (const char *, ...);

int main (int argc, const char **argv)
{
	CPrintf ("###### Custom ######\n"
		 "1 = |%s|\n2 = |%d|\n3 = |%x|\n4 = |%c|\n"
		 "5 = |%d|\n6 = |%x|\n7 = |%c|\n8 = |%d|\n"
		 "I %s %x %d%%%c%b\n", 
		 "DIO", 1337, 3802, 'e', 228, 42, 'u', 322, "love", 3802, 100, 33, 15);
	
	return 0;
}
