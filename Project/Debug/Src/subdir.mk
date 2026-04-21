################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Src/MoT_main03.c \
../Src/syscalls--left_in_to_quiet_warnings.c 

S_UPPER_SRCS += \
../Src/HW_userCOM05.S \
../Src/SysTick_definitions.S \
../Src/SystemClock_init2.S \
../Src/stm32fL4xx_TIM2_demo--broken.S 

OBJS += \
./Src/HW_userCOM05.o \
./Src/MoT_main03.o \
./Src/SysTick_definitions.o \
./Src/SystemClock_init2.o \
./Src/stm32fL4xx_TIM2_demo--broken.o \
./Src/syscalls--left_in_to_quiet_warnings.o 

S_UPPER_DEPS += \
./Src/HW_userCOM05.d \
./Src/SysTick_definitions.d \
./Src/SystemClock_init2.d \
./Src/stm32fL4xx_TIM2_demo--broken.d 

C_DEPS += \
./Src/MoT_main03.d \
./Src/syscalls--left_in_to_quiet_warnings.d 


# Each subdirectory must supply rules for building sources it contributes
Src/%.o: ../Src/%.S Src/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/cales/OneDrive/Documents/ENEE440/Workspaces/HW09_Problem1_ws/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"
Src/%.o Src/%.su Src/%.cyclo: ../Src/%.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DSTM32 -DSTM32G491RETx -DSTM32G4 -c -IC:/Users/cales/OneDrive/Documents/ENEE440/Workspaces/HW09_Problem1_ws/Project/Inc -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Src

clean-Src:
	-$(RM) ./Src/HW_userCOM05.d ./Src/HW_userCOM05.o ./Src/MoT_main03.cyclo ./Src/MoT_main03.d ./Src/MoT_main03.o ./Src/MoT_main03.su ./Src/SysTick_definitions.d ./Src/SysTick_definitions.o ./Src/SystemClock_init2.d ./Src/SystemClock_init2.o ./Src/stm32fL4xx_TIM2_demo--broken.d ./Src/stm32fL4xx_TIM2_demo--broken.o ./Src/syscalls--left_in_to_quiet_warnings.cyclo ./Src/syscalls--left_in_to_quiet_warnings.d ./Src/syscalls--left_in_to_quiet_warnings.o ./Src/syscalls--left_in_to_quiet_warnings.su

.PHONY: clean-Src

