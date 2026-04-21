################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_system/HW_userCOM04.S 

OBJS += \
./Src/MoT_system/HW_userCOM04.o 

S_UPPER_DEPS += \
./Src/MoT_system/HW_userCOM04.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_system/%.o: ../Src/MoT_system/%.S Src/MoT_system/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"D:/_umd/2024-09-01/ENEE440_F24/_work/1028_MoT_Nucleo-G491/MoT_Nucleo-G491.ws2/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_system

clean-Src-2f-MoT_system:
	-$(RM) ./Src/MoT_system/HW_userCOM04.d ./Src/MoT_system/HW_userCOM04.o

.PHONY: clean-Src-2f-MoT_system

