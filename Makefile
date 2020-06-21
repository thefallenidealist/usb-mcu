# created 141129
# updated 190921 change to clang (8.0 instead of 3.9)

CLANG_VERSION=90

NAME	= tinyusb
CC	= clang$(CLANG_VERSION)

LD  		= ld.lld$(CLANG_VERSION)
OBJCOPY 	= llvm-objcopy$(CLANG_VERSION)
OBJDUMP 	= llvm-objdump$(CLANG_VERSION)
SIZE		= llvm-size$(CLANG_VERSION)
AR  		= llvm-ar$(CLANG_VERSION)

TARGET	= --target=thumbv7m-unknown-none-eabi -mthumb -march=armv7m -mfloat-abi=soft -mfpu=none
CPU		= -mcpu=cortex-m3
OPTS	?= -Os -g3

DIRS 	+= -I . -I /usr/local/arm-none-eabi/include \
		   -I src/ \
		   -I hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Include \
		   -I hw/mcu/st/st_driver/CMSIS/Include \
		   -I hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Inc \
		   -I hw/bsp/stm32f103bluepill/ \
		   -I hw/
# GCC x.y includes (like stddef.h)
DIRS 	+= -I $(shell arm-none-eabi-gcc -print-search-dirs | awk '/install/{print $$2}')/include

LINKER_FILE		= hw/bsp/stm32f103bluepill/STM32F103XB_FLASH.ld
DEFINES += -DSTM32F103xB -DCFG_TUSB_MCU=OPT_MCU_STM32F1
DIR_BUILD	?= ./build

COMMON_FLAGS	= $(TARGET) $(CPU) $(OPTS) -ffreestanding $(DEFINES) $(DIRS)

LIBRARY="" 	# us in-tree libc from Debian, if not used, it will link but at runtime:
# Program received signal SIGSEGV, Segmentation fault.
# LoopFillZerobss () at hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Source/Templates/gcc/startup_stm32f103xb.s:95
# 0x08000482 LoopFillZerobss+10 blx    0x800010c <__libc_init_array>
CFLAGS  	= $(COMMON_FLAGS) -std=c11 -flto -gdwarf-2
ASFLAGS  	= $(COMMON_FLAGS)
LDFLAGS 	= --Bstatic --gc-sections -L $(LIBRARY) -Llib \
			  --Map=$(DIR_BUILD)/$(NAME).map \
			  --script $(LINKER_FILE)

SRCS += hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Source/Templates/gcc/startup_stm32f103xb.s
SRCS += hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Source/Templates/system_stm32f1xx.c
SRCS += hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal.c
SRCS += hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_cortex.c
SRCS += hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc.c
SRCS += hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc_ex.c
SRCS += hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio.c
SRCS += hw/bsp/board.c
SRCS += hw/bsp/stm32f103bluepill/stm32f103bluepill.c
SRCS += src/tusb.c
SRCS += src/common/tusb_fifo.c
SRCS += src/device/usbd.c
SRCS += src/device/usbd_control.c
SRCS += src/class/cdc/cdc_device.c
SRCS += src/class/dfu/dfu_rt_device.c
SRCS += src/class/hid/hid_device.c
SRCS += src/class/midi/midi_device.c
SRCS += src/class/msc/msc_device.c
SRCS += src/class/net/net_device.c
SRCS += src/class/usbtmc/usbtmc_device.c
SRCS += src/class/vendor/vendor_device.c
SRCS += src/portable/st/stm32_fsdev/dcd_stm32_fsdev.c

OBJS1 = $(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(patsubst %.s,%.o,$(SRCS)))) # rename .c, .cpp and .s to .o
OBJS2 = $(notdir $(OBJS1))	# remove path, leave just file.o
OBJS3 = $(addprefix $(DIR_BUILD)/,$(OBJS2))
OBJS  = $(OBJS3)

all: lib

# create dirs if they don't exist
dirs: $(DIR_BUILD)

clean:
	rm -rf $(DIR_BUILD)/

# build all .c files with one recipe (must be one recipe for all files)
vpath %.c \
	hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Source/Templates/ \
	hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/ \
	hw/bsp hw/bsp/stm32f103bluepill/ \
	src src/common src/device \
	src/class/dfu src/class/cdc src/class/dfu src/class/hid src/class/midi src/class/msc src/class/net \
	src/class/usbtmc src/class/vendor src/portable/st/stm32_fsdev \
	examples/device/hid_composite/src/
$(DIR_BUILD)/%.o: %.c
	@echo CC $<
	@$(CC) $(CFLAGS) -c -o $@ $<

vpath %.s hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Source/Templates/gcc/
$(DIR_BUILD)/%.o: %.s
	@echo AS $<
	@$(CC) $(ASFLAGS) -x assembler-with-cpp -c -o $@ $<

lib: dirs $(OBJS)
	@echo Creating lib
	@$(AR) rcs $(DIR_BUILD)/lib$(NAME).a $(OBJS)
	@ls -lh $(DIR_BUILD)/lib$(NAME).a
	@echo "You will need to provide main.c, tusb_config.h, usb_descriptors.c, usb_descriptors.h"

example: dirs $(OBJS)
	@echo LD $@
	@$(LD) $(LDFLAGS) $(OBJS) -o $(DIR_BUILD)/$@.elf -lc
	@$(SIZE) $(DIR_BUILD)/$@.elf

$(DIR_BUILD):
	@mkdir -p $(DIR_BUILD)
