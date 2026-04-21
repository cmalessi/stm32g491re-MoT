################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Startup/startup_stm32g491retx.S 

OBJS += \
./Startup/startup_stm32g491retx.o 

S_UPPER_DEPS += \
./Startup/startup_stm32g491retx.d 


# Each subdirectory must supply rules for building sources it contributes
Startup/%.o: ../Startup/%.S Startup/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/cales/OneDrive/Documents/ENEE440/Workspaces/HW09_Problem1_ws/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Startup

clean-Startup:
	-$(RM) ./Startup/startup_stm32g491retx.d ./Startup/startup_stm32g491retx.o

.PHONY: clean-Startup

