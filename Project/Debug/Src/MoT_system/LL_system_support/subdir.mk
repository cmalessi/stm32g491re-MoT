################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_system/LL_system_support/SysTick48MHz.S \
../Src/MoT_system/LL_system_support/stm32L476xx_HCLK48MHz_01.S 

OBJS += \
./Src/MoT_system/LL_system_support/SysTick48MHz.o \
./Src/MoT_system/LL_system_support/stm32L476xx_HCLK48MHz_01.o 

S_UPPER_DEPS += \
./Src/MoT_system/LL_system_support/SysTick48MHz.d \
./Src/MoT_system/LL_system_support/stm32L476xx_HCLK48MHz_01.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_system/LL_system_support/%.o: ../Src/MoT_system/LL_system_support/%.S Src/MoT_system/LL_system_support/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"D:/_umd/2024-09-01/ENEE440_F24/_work/1028_MoT_Nucleo-G491/MoT_Nucleo-G491.ws2/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_system-2f-LL_system_support

clean-Src-2f-MoT_system-2f-LL_system_support:
	-$(RM) ./Src/MoT_system/LL_system_support/SysTick48MHz.d ./Src/MoT_system/LL_system_support/SysTick48MHz.o ./Src/MoT_system/LL_system_support/stm32L476xx_HCLK48MHz_01.d ./Src/MoT_system/LL_system_support/stm32L476xx_HCLK48MHz_01.o

.PHONY: clean-Src-2f-MoT_system-2f-LL_system_support

