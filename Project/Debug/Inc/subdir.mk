################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Inc/bit-op_macros.S 

OBJS += \
./Inc/bit-op_macros.o 

S_UPPER_DEPS += \
./Inc/bit-op_macros.d 


# Each subdirectory must supply rules for building sources it contributes
Inc/%.o: ../Inc/%.S Inc/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/cales/OneDrive/Documents/ENEE440/Workspaces/HW09_Problem1_ws/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Inc

clean-Inc:
	-$(RM) ./Inc/bit-op_macros.d ./Inc/bit-op_macros.o

.PHONY: clean-Inc

