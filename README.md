# Linux-0.11 on MacOS
从 https://github.com/ETOgaosion/Linux-0.11-MacOS 克隆过来，修改了一些文件让源码可以编译和运行在我的 MacOS（13.6 (22G120)） 上（原仓库的 hdc 镜像和 gcc 的入参似乎有问题，导致我的设备无法顺利运行）

# mac 环境依赖
```shell
# 安装编译套件、gdb
brew install i386-elf-binutils i386-elf-gcc
brew install i386-elf-gdb

# 安装 qemu
brew install qemu

# 安装 bochs
brew install bochs

# 设置 bochs 的环境变量，在我的设备上，xxx 为 /usr/local/Cellar/bochs/2.8/share
export BXSHARE=xxx
```

# 基本操作
```shell
make # 编译源码
make start # 使用 qemu 运行内核
make bochs # 使用 bochs 运行内核

# 更多说明见原仓库的 readme：README.backup.md 文件，或直接看根目录下的 Makefile
```

# 一些调试时可以参考的文件
执行编译后，./out 目录下会出现以下文件，断点调试时可参考
- bootsect.dump
  - bootsect.s 的反汇编文件，包含源码和地址，作为 MBR
- setup.dump
  - setup.s 的反汇编文件，包含源码和地址，被 MBR 加载（0x90200 是起始地址）
- system.dump
  - head.s + 其他源码编译后的内核反汇编文件
- system.map
  - 内核的符号地址，如 0x6738 是 main 函数的地址（刚好 boot 阶段挪来挪去后 system 的起始地址是 0）