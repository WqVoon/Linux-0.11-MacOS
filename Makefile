# indicate the Hardware $(IMAGE) file
HDA_IMG = hdc-0.11.img

# build target image
IMAGE = build/image

# indicate the path of the calltree
CALLTREE=$(shell find tools/ -name "calltree" -perm 755 -type f)

#
# if you want the ram-disk device, define this to be the
# size in blocks.
#
RAMDISK =  #-DRAMDISK=512

# This is a basic Makefile for setting the general configuration
include Makefile.header

LDFLAGS	+= -Ttext 0 -e startup_32
CFLAGS	+= $(RAMDISK) -Iinclude
CPP	+= -Iinclude

#
# ROOT_DEV specifies the default root-device when making the image.
# This can be either FLOPPY, /dev/xxxx or empty, in which case the
# default of /dev/hd6 is used by 'build'.
#
ROOT_DEV= #FLOPPY 

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o
DRIVERS =kernel/blk_drv/blk_drv.a kernel/chr_drv/chr_drv.a
MATH	=kernel/math/math.a
LIBS	=lib/lib.a

.PHONY: .c.s .s.o .c.o all check prepare dump disk clean distclean backup dep start debug cg callgraph help

.c.s:
	@$(CC) $(CFLAGS) -S -o $*.s $<
.s.o:
	@$(AS)  -o $*.o $<
.c.o:
	@$(CC) $(CFLAGS) -c -o $*.o $<

all:	check prepare $(IMAGE) dump

check:
	@echo "Running on OS: $(UNAME)"
	@if [ $(UNAME) != "Darwin" ]; then \
		echo "We only support MacOS"; \
		exit 1; \
	else \
		echo "$(UNAME) OS is supported"; \
	fi

prepare:
	@mkdir -p build
	@mkdir -p out

dump:
	@objdump -S build/system > out/system.dump
	@objdump -S boot/bootsect.o > out/bootsect.dump
	@objdump -S boot/setup.o > out/setup.dump

$(IMAGE): boot/bootsect boot/setup build/system
	@cp -f build/system build/system.tmp
	@$(STRIP) build/system.tmp
	@$(OBJCOPY) -O binary -R .note -R .comment build/system.tmp tools/kernel
	@scripts/image_build.sh boot/bootsect boot/setup tools/kernel $(IMAGE) $(ROOT_DEV)
	@rm build/system.tmp
	@rm -f tools/kernel
	@sync

disk: $(IMAGE)
	@dd bs=8192 if=$(IMAGE) of=/dev/fd0

boot/head.o: boot/head.s
	@make head.o -C boot/

build/system:	boot/head.o init/main.o \
		$(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)
	@$(LD) $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	$(DRIVERS) \
	$(MATH) \
	$(LIBS) \
	-o build/system 
	@nm build/system | grep -v '\(compiled\)\|\(\.o$$\)\|\( [aU] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)'| sort > out/system.map 

kernel/math/math.a:
	@make -C kernel/math

kernel/blk_drv/blk_drv.a:
	@make -C kernel/blk_drv

kernel/chr_drv/chr_drv.a:
	@make -C kernel/chr_drv

kernel/kernel.o:
	@make -C kernel

mm/mm.o:
	@make -C mm

fs/fs.o:
	@make -C fs

lib/lib.a:
	@make -C lib

boot/setup: boot/setup.s
	@make setup -C boot

boot/bootsect: boot/bootsect.s
	@make bootsect -C boot

tmp.s:	boot/bootsect.s build/system
	@(echo -n "SYSSIZE = (";ls -l build/system | grep system \
		| cut -c25-31 | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
	@cat boot/bootsect.s >> tmp.s

clean:
	@rm -rf build out
	@rm -f boot/bootsect boot/setup
	@rm -f init/*.o build/system boot/*.o typescript* info bochsout.txt
	@for i in mm fs kernel lib boot; do make clean -C $$i; done 
info:
	@make clean
	@script -q -c "make all"
	@cat typescript | col -bp | grep -E "warning|Error" > info
	@cat info

distclean: clean
	@rm -f tag cscope* linux-0.11.* $(CALLTREE)
	@(find tools/calltree -name "*.o" | xargs -i rm -f {})
	@make clean -C tools/calltree
	@make clean -C tools/bochs/bochs-2.3.7

backup: clean
	@(cd .. ; tar cf - linux | compress16 - > backup.Z)
	@sync

dep:
	@sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	@(for i in init/*.c;do echo -n "init/";$(CPP) -M $$i;done) >> tmp_make
	@cp tmp_make Makefile
	@for i in fs kernel mm; do make dep -C $$i; done

start:
	@qemu-system-i386 -m 16M -boot a -fda $(IMAGE) -hda $(HDA_IMG)

debug:
	@qemu-system-i386 -m 16M -boot a -fda $(IMAGE) -hda $(HDA_IMG) -s -S

gdb: # 删掉了原仓库的 .gdbinit，所以需要在启动时主动增加额外的命令
	@gdb -ex 'target remote :1234' ./build/system

bochs:
	@bochs -f bochs.conf

cg: callgraph

callgraph:
	@./scripts/callgraph.sh -f main -d ./init -D 10

help:
	@echo "<<<<This is the basic help info of linux-0.11>>>"
	@echo ""
	@echo "Usage:"
	@echo "     make --generate a kernel floppy $(IMAGE) with a fs on hda1"
	@echo "     make start -- start the kernel in qemu"
	@echo "     make debug -- debug the kernel in qemu & gdb at port 1234"
	@echo "     make disk  -- generate a kernel $(IMAGE) & copy it to floppy"
	@echo "     make cscope -- genereate the cscope index databases"
	@echo "     make tags -- generate the tag file"
	@echo "     make cg -- generate callgraph of the system architecture"
	@echo "     make clean -- clean the object files"
	@echo "     make distclean -- only keep the source code files"
	@echo ""
	@echo "Note!:"
	@echo "     * You need to install the following basic tools:"
	@echo "          ubuntu|debian, qemu|bochs, ctags, cscope, calltree, graphviz "
	@echo "          vim-full, build-essential, hex, dd, gcc 4.3.2..."
	@echo "     * Becarefull to change the compiling options, which will heavily"
	@echo "     influence the compiling procedure and running result."
	@echo ""
	@echo "Author:"
	@echo "     * 1991, linus write and release the original linux 0.95(linux 0.11)."
	@echo "     * 2005, jiong.zhao<gohigh@sh163.net> release a new version "
	@echo "     which can be used in RedHat 9 along with the book 'Explaining "
	@echo "     Linux-0.11 Completly', and he build a site http://www.oldlinux.org"
	@echo "     * 2008, falcon<wuzhangjin@gmail.com> release a new version which can be"
	@echo "     used in ubuntu|debian 32bit|64bit with gcc 4.3.2, and give some new "
	@echo "     features for experimenting. such as this help info, boot/bootsect.s and"
	@echo "     boot/setup.s with AT&T rewritting, porting to gcc 4.3.2 :-)"
	@echo ""
	@echo "<<<Be Happy To Play With It :-)>>>"

### Dependencies:
init/main.o: init/main.c include/unistd.h include/sys/stat.h \
	include/sys/types.h include/sys/times.h include/sys/utsname.h \
	include/utime.h include/time.h include/linux/tty.h include/termios.h \
	include/linux/sched.h include/linux/head.h include/linux/fs.h \
	include/linux/mm.h include/signal.h include/asm/system.h \
	include/asm/io.h include/stddef.h include/stdarg.h include/fcntl.h
