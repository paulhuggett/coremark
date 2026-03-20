# The spike executable should be on the path.

ifndef TOOLCHAIN_ROOT
$(error "Set TOOLCHAIN_ROOT to the toolchain root directory (clang-keysom)")
endif

RVARCH:=rv32imc

LIBS =                                                        \
  $(TOOLCHAIN_ROOT)/lib/keysom/libclang_rt.builtins-riscv32.a \
  $(TOOLCHAIN_ROOT)/picolibc/rv32-keysom/lib/libc.a           \
  $(TOOLCHAIN_ROOT)/picolibc/rv32-keysom/lib/crt0-semihost.o

# Flag : OUTFLAG
#	Use this flag to define how to to get an executable (e.g -o)
OUTFLAG= -o
# Flag : CC
#	Use this flag to define compiler to use
CC 		= $(TOOLCHAIN_ROOT)/bin/clang
# Flag : LD
#	Use this flag to define compiler to use
LD		= $(CC)
# Flag : AS
#	Use this flag to define compiler to use
AS		= $(CC)
# Flag : CFLAGS
#	Use this flag to define compiler options. Note, you can add compiler options from the command line using XCFLAGS="other flags"
PORT_CFLAGS =      \
  -march=$(RVARCH) \
  -O3              \
  -I $(TOOLCHAIN_ROOT)/picolibc/rv32-keysom/include

FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS) $(LFLAGS_END)"
CFLAGS = $(PORT_CFLAGS) -I$(PORT_DIR) -I. -DFLAGS_STR=\"$(FLAGS_STR)\"
#Flag : LFLAGS_END
#	Define any libraries needed for linking or other flags that should come at the end of the link line (e.g. linker scripts).
#	Note : On certain platforms, the default clock_gettime implementation is supported but requires linking of librt.
LFLAGS_END =
# Flag : SEPARATE_COMPILE
SEPARATE_COMPILE=1

# How we create an object file and link.
OBJOUT 	= -o
LFLAGS 	=                     \
  -march=$(RVARCH)            \
  -nostdlib                   \
  -O3                         \
  $(LIBS)                     \
  -Wl,-T,$(PORT_DIR)/spike.ld \
  -Wl,--Map=map.txt           \
  -Wl,--gc-sections
ASFLAGS = -c
OFLAG 	= -o
COUT 	= -c

LFLAGS_END =
# Flag : PORT_SRCS
# 	Port specific source files can be added here
#	You may also need cvt.c if the fcvt functions are not provided as intrinsics by your compiler!
PORT_SRCS =                 \
  $(PORT_DIR)/core_portme.c \
  $(PORT_DIR)/spike_glue.c

vpath %.c $(PORT_DIR)
vpath %.s $(PORT_DIR)
PORT_OBJS = $(PORT_SRCS:%.c=%.o)

LOAD = echo Loading done

# Use the simulator to run the executable. Spike is assumed to be on the path.
RUN = spike --isa=$(RVARCH)_Zicntr -m0x80000000:0x1000000

OEXT = .o
EXE = .elf

$(OPATH)$(PORT_DIR)/%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)$(PORT_DIR)/%$(OEXT) : %.s
	$(AS) $(ASFLAGS) $< $(OBJOUT) $@

# Target : port_pre% and port_post%
# For the purpose of this simple port, no pre or post steps needed.

.PHONY : port_prebuild port_postbuild port_prerun port_postrun port_preload port_postload
port_pre% port_post% :

# FLAG : OPATH
# Path to the output folder. Default - current folder.
OPATH = ./
MKDIR = mkdir -p
