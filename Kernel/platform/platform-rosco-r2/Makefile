
CSRCS = devtty.c
CSRCS += devices.c main.c libc.c
CSRCS += devch375.c devch375_discard.c

ASRCS = p68000.S crt0.S
ASRCS += tricks.S

DSRCS = ../../dev/mbr.c ../../dev/blkdev.c
DSRCS += ../../dev/devsd.c ../../dev/devsd_discard.c
DOBJS = $(patsubst ../../dev/%.c,%.o, $(DSRCS))

LSRCS = ../../lib/68000exception.c ../../lib/68000usercopy.c
LSRCS += ../../lib/68000relocate.c
LOBJS = $(patsubst ../../lib/%.c,%.o, $(LSRCS))

COBJS = $(CSRCS:.c=$(BINEXT))
AOBJS = $(ASRCS:.S=.o)
OBJS  = $(COBJS) $(AOBJS) $(DOBJS) $(LOBJS)

CROSS_CCOPTS += -I../../dev/

all:	$(OBJS)

$(COBJS): %.o: %.c
	$(CROSS_CC) $(CROSS_CCOPTS) -c $<

$(AOBJS): %.o: %.S
	$(CROSS_AS) $(ASOPTS) $< -o $*.o

$(DOBJS): %.o: ../../dev/%.c
	$(CROSS_CC) $(CROSS_CCOPTS) -c $<

$(LOBJS): %.o: ../../lib/%.c
	$(CROSS_CC) $(CROSS_CCOPTS) -c $<

tricks.S: ../../lib/68000flat.S

clean:
	rm -f *.o fuzix.elf core *~ fuzix.dis

image:
	$(CROSS_LD) -M -o fuzix.elf -T fuzix.ld p68000.o ../../start.o \
	  ../../version.o ../../cpu-68000/lowlevel-68000.o tricks.o \
	  main.o ../../timer.o ../../kdata.o 68000exception.o \
	  devices.o ../../devio.o ../../filesys.o ../../process.o \
	  ../../inode.o ../../syscall_fs.o ../../syscall_proc.o \
	  ../../syscall_other.o ../../mm.o ../../flat.o ../../blk512.o \
	  ../../tty.o ../../devsys.o ../../usermem.o ../../syscall_fs2.o \
	  ../../syscall_fs3.o ../../syscall_exec32.o ../../syscall_exec.o \
	  blkdev.o mbr.o 68000relocate.o \
	  devsd.o devsd_discard.o \
	  devch375.o devch375_discard.o \
	  68000usercopy.o ../../cpu-68000/usermem_std-68000.o devtty.o \
	  libc.o ../../malloc.o ../../level2.o ../../syscall_level2.o \
	  ../../select.o > ../../fuzix.map
	$(CROSS_COMPILE)objcopy fuzix.elf -O binary ../../fuzix.bin
	m68k-elf-objdump --disassemble -S fuzix.elf > fuzix.dis

IMAGES = $(FUZIX_ROOT)/Images/$(TARGET)

diskimage:
	# Make a blank disk image with partition
	dd if=$(FUZIX_ROOT)/Standalone/filesystem-src/parttab.40M of=$(IMAGES)/disk.img bs=40017920 conv=sync,swab
	# Add the file system
	dd if=$(IMAGES)/filesys.img of=$(IMAGES)/disk.img bs=512 seek=2048 conv=notrunc,swab
	# Add the kernel
	dd if=../../fuzix.bin of=$(IMAGES)/disk.img bs=512 seek=2 conv=notrunc,swab
	# Make an emulator image of it
	cat $(FUZIX_ROOT)/Standalone/filesystem-src/idehdr.40M $(IMAGES)/disk.img > $(IMAGES)/emu-ide.img
