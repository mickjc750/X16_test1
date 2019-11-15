all:
	acme -f cbm -DMACHINE_C64=0 -o TEST1.PRG TEST1.ASM
clean:
	rm -f *.prg

