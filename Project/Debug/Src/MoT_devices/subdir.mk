################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_devices/MoTdevice_blueBUTTON.S \
../Src/MoT_devices/MoTdevice_device3.S \
../Src/MoT_devices/MoTdevice_device4.S \
../Src/MoT_devices/MoTdevice_device5.S \
../Src/MoT_devices/MoTdevice_device6.S \
../Src/MoT_devices/MoTdevice_userLED.S 

OBJS += \
./Src/MoT_devices/MoTdevice_blueBUTTON.o \
./Src/MoT_devices/MoTdevice_device3.o \
./Src/MoT_devices/MoTdevice_device4.o \
./Src/MoT_devices/MoTdevice_device5.o \
./Src/MoT_devices/MoTdevice_device6.o \
./Src/MoT_devices/MoTdevice_userLED.o 

S_UPPER_DEPS += \
./Src/MoT_devices/MoTdevice_blueBUTTON.d \
./Src/MoT_devices/MoTdevice_device3.d \
./Src/MoT_devices/MoTdevice_device4.d \
./Src/MoT_devices/MoTdevice_device5.d \
./Src/MoT_devices/MoTdevice_device6.d \
./Src/MoT_devices/MoTdevice_userLED.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_devices/%.o: ../Src/MoT_devices/%.S Src/MoT_devices/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/cales/OneDrive/Documents/ENEE440/Workspaces/HW09_Problem1_ws/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_devices

clean-Src-2f-MoT_devices:
	-$(RM) ./Src/MoT_devices/MoTdevice_blueBUTTON.d ./Src/MoT_devices/MoTdevice_blueBUTTON.o ./Src/MoT_devices/MoTdevice_device3.d ./Src/MoT_devices/MoTdevice_device3.o ./Src/MoT_devices/MoTdevice_device4.d ./Src/MoT_devices/MoTdevice_device4.o ./Src/MoT_devices/MoTdevice_device5.d ./Src/MoT_devices/MoTdevice_device5.o ./Src/MoT_devices/MoTdevice_device6.d ./Src/MoT_devices/MoTdevice_device6.o ./Src/MoT_devices/MoTdevice_userLED.d ./Src/MoT_devices/MoTdevice_userLED.o

.PHONY: clean-Src-2f-MoT_devices

