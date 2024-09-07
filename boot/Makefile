include ../Makefile.header

LDFLAGS	+= -Ttext 0

all: bootsect setup

bootsect: bootsect.asm
	@nasm bootsect.asm -o bootsect

setup: setup.asm
	@nasm setup.asm -o setup

head.o: head.s
	@$(AS) -o head.o head.s

clean:
	@rm -f bootsect bootsect.o setup setup.o head.o
