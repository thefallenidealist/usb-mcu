# USB lib for MCU

Small USB lib for use on STM32F1 MCU. Stripped down version of [TinyUSB](https://github.com/hathach/tinyusb) meant to be built with clang/LLVM on FreeBSD (not a strict requirement, works also (at least) on Debian 10).

#### Table of Contents  
* [Using](#using)  
* [Linking](#linking-with-app)
* [Licence](#licence)
* [TODO](#todo)
* [Versions](#versions)

## Using
Running `./fetch` will download tinyusb, newlib libc from Debian package and all needed submodules and copy only needed bits and parts. Not needed as this repo already containts that parts.

To make static library (will use `examples/device/hid_generic_inout/src/tusb_config.h`) which later will be linked with your application run `gmake`.
If library will not be linked with clang then probably good idea is to disable LTO (remove `-flto` from CFLAGS)

```console
% gmake
AS hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Source/Templates/gcc/startup_stm32f103xb.s                                                                                                   
Using tusb_config.h from example:                                                                                                                                                             
ln -s examples/device/hid_generic_inout/src/tusb_config.h .                                                                                                                                   
CC hw/mcu/st/st_driver/CMSIS/Device/ST/STM32F1xx/Source/Templates/system_stm32f1xx.c                                                                                                          
CC hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal.c
CC hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_cortex.c
CC hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc.c
CC hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc_ex.c
CC hw/mcu/st/st_driver/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio.c
CC hw/bsp/board.c
CC hw/bsp/stm32f103bluepill/stm32f103bluepill.c 
CC src/tusb.c
CC src/common/tusb_fifo.c
CC src/device/usbd.c
CC src/device/usbd_control.c
CC src/class/cdc/cdc_device.c
CC src/class/dfu/dfu_rt_device.c
CC src/class/hid/hid_device.c
CC src/class/midi/midi_device.c
CC src/class/msc/msc_device.c
CC src/class/net/net_device.c
CC src/class/usbtmc/usbtmc_device.c
CC src/class/vendor/vendor_device.c
CC src/portable/st/stm32_fsdev/dcd_stm32_fsdev.c
Creating lib
-rw-r--r--  1 johnny  johnny   292K Jun 26 09:31 ./build/libusb.a
You will need to provide main.c, tusb_config.h, usb_descriptors.c, usb_descriptors.h
```

### Linking with app
Make static library as stated above and link your firmware against it (`LD -o firmware.elf <bunch of files.o> -L <path to libusb.a> -lusb`).  
Library with example USB HID "application" is around 9 kB.  

Example:  
```
LD app
ld.lld90 --Bstatic --gc-sections -Ltinyusb/build/ --script STM32F103XB_FLASH.ld ./build/usb_descriptors.o ./build/main.o -o ./build/app.elf -lc -lusb
   text    data     bss     dec     hex filename
   8684    1564     784   11032    2b18 ./build/app.elf
```

## Licence
MIT. See [TinyUSB licence](https://github.com/hathach/tinyusb#license) for more details.  

## TODO
- tusb_config.h hard configured for HID, recompilation will be needed if class other than HID is used
- CFG_TUD_HID_BUFSIZE also hardcoded

## Versions
200621 Initial version of Makefile, fetch and README.md created
```
% gmake -v
GNU Make 4.3
Built for amd64-portbld-freebsd12.1
Copyright (C) 1988-2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

% cc -v
FreeBSD clang version 8.0.1 (tags/RELEASE_801/final 366581) (based on LLVM 8.0.1)
Target: x86_64-unknown-freebsd12.1
Thread model: posix
InstalledDir: /usr/bin

% arm-none-eabi-gcc -v
Using built-in specs.
COLLECT_GCC=arm-none-eabi-gcc
COLLECT_LTO_WRAPPER=/usr/local/libexec/gcc/arm-none-eabi/8.4.0/lto-wrapper
Target: arm-none-eabi
Configured with: /wrkdirs/usr/ports/devel/arm-none-eabi-gcc/work/gcc-8.4.0/configure --disable-libstdcxx --disable-multilib --target=arm-none-eabi --disable-nls --enable-languages=c,c++ --enable-gnu-indirect-function --without-headers --with-gmp=/usr/local --with-pkgversion='FreeBSD Ports Collection for armnoneeabi' --with-system-zlib --with-gxx-include-dir=/usr/include/c++/v1/ --with-sysroot=/ --with-as=/usr/local/bin/arm-none-eabi-as --with-ld=/usr/local/bin/arm-none-eabi-ld --prefix=/usr/local --localstatedir=/var --mandir=/usr/local/man --infodir=/usr/local/share/info/ --build=x86_64-unknown-freebsd12.1
Thread model: single
gcc version 8.4.0 (FreeBSD Ports Collection for armnoneeabi) 

% uname -sr
FreeBSD 12.1-RELEASE-p6
```
