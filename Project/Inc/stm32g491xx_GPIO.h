// stm32g491xx_GPIO.h wmh 2024-09-22 
#include "stm32g491xx_defines.h"	

//offsets in GPIO struct
#define GPIO_MODER    0x00   /*!< GPIO port mode register,               Address offset: 0x00      */
#define GPIO_OTYPER   0x04   /*!< GPIO port output type register,        Address offset: 0x04      */
#define GPIO_OSPEEDR  0x08   /*!< GPIO port output speed register,       Address offset: 0x08      */
#define GPIO_PUPDR    0x0C   /*!< GPIO port pull-up/pull-down register,  Address offset: 0x0C      */
#define GPIO_IDR      0x10   /*!< GPIO port input data register,         Address offset: 0x10      */
#define GPIO_ODR      0x14   /*!< GPIO port output data register,        Address offset: 0x14      */
#define GPIO_BSRR     0x18   /*!< GPIO port bit set/reset  register,     Address offset: 0x18      */
#define GPIO_LCKR     0x1C   /*!< GPIO port configuration lock register, Address offset: 0x1C      */
#define GPIO_AFRL     0x20   /*!< GPIO alternate function registers,     Address offset: 0x20      */
#define GPIO_AFRH     0x24   /*!< GPIO alternate function registers,     Address offset:  0x24     */
#define GPIO_BRR      0x28   /*!< GPIO Bit Reset register,               Address offset: 0x28      */

