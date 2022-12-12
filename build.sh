#!/usr/bin/env bash

gcc main.c                           \
  -c                                 \
  -fno-stack-protector               \
  -fpic                              \
  -fshort-wchar                      \
  -mno-red-zone                      \
  -I /usr/include/efi                \
  -I /usr/include/efi/x86_64         \
  -DEFI_FUNCTION_WRAPPER             \
  -o main.o

ld main.o                        \
  /usr/lib/crt0-efi-x86_64.o     \
  -nostdlib                      \
  -znocombreloc                  \
  -T /usr/lib/elf_x86_64_efi.lds \
  -shared                        \
  -Bsymbolic                     \
  -L /usr/lib                    \
  -l:libgnuefi.a                 \
  -l:libefi.a                    \
  -o main.so

objcopy -j .text          \
  -j .sdata               \
  -j .data                \
  -j .dynamic             \
  -j .dynsym              \
  -j .rel                 \
  -j .rela                \
  -j .reloc               \
  --target=efi-app-x86_64 \
  main.so                 \
  main.efi

dd if=/dev/zero of=./uefi.img bs=512 count=93750

parted ./uefi.img -s -a minimal mklabel gpt
parted ./uefi.img -s -a minimal mkpart EFI FAT16 2048s 93716s
parted ./uefi.img -s -a minimal toggle 1 boot

dd if=/dev/zero of=/tmp/part.img bs=512 count=91669
mformat -i /tmp/part.img -h 32 -t 32 -n 64 -c 1

mcopy -i /tmp/part.img ./main.efi ::

dd if=/tmp/part.img of=./uefi.img bs=512 count=91669 seek=2048 conv=notrunc
