Linux-0.11
==========

Modified project setup from [https://github.com/yuan-xy/Linux-0.11/blob/master](https://github.com/yuan-xy/Linux-0.11/blob/master)

The old Linux kernel source ver 0.11 which has been tested under modern Linux,  Mac OSX and Windows.

Clone instruction:

```sh
git lfs clone git@github.com:ETOgaosion/linux.git
```

## 1. Build on Linux

### 1.1. Linux Setup

* a linux distribution: debian , ubuntu and mint are recommended
* some tools: gcc gdb qemu
* a linux-0.11 hardware image file: hdc-0.11.img, please download it from http://www.oldlinux.org, or http://mirror.lzu.edu.cn/os/oldlinux.org/, ant put it in the root directory.
* Now, This version already support the Ubuntu 16.04, enjoy it.

### 1.2. linux-0.11 playground

```sh
make help		// get help
make  		    // compile
make start		// boot it on qemu
make debug		// debug it via qemu & gdb, you'd start gdb to connect it.
```

```sh
gdb tools/system
(gdb) target remote :1234
(gdb) b main
(gdb) c
```

## 2. Build on Mac OS X

### 2.1. Mac OS X Setup

* install cross compiler gcc, gdb and binutils

```sh
brew tap nativeos/i386-elf-toolchain
brew install i386-elf-binutils i386-elf-gcc
```

* install qemu
* install gdb. you need download the gdb source and compile it to use gdb because port doesn't provide i386-elf-gdb, or you can use the pre-compiled gdb in the tools directory.
* a linux-0.11 hardware image file: hdc-0.11.img

```sh
brew install qemu
```

optional
```sh
wget ftp://ftp.gnu.org/gnu/gdb/gdb-7.4.tar.bz2
tar -xzvf gdb-7.4.tar.bz2
cd gdb-7.4
./configure --target=i386-elf
make
```

### 2.2. linux-0.11 playground
same as section 1.2


## 3. Build on Windows
todo...
