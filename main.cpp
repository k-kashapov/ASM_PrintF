extern "C" int CPrintf (const char *, ...);

int main (int argc, const char **argv)
{
	CPrintf ("JOJO |%s|\n1337 = |%d|\naaa = |%x|\nsym = |%c|\n", "DIO", 1337, 3802, 'e');

	return 0;
}
