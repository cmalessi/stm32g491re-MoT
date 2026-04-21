//stm32G491xx_FLASH.h wmh 2024-08-21 : : FLASH register offsets extracted from stm2G491xx.h

#include "stm32g491xx_defines.h"	

//FLASH register ofsets in the FLASH control register struct
#define FLASH_ACR         0x00     /*!< FLASH access control register,            Address offset: 0x00 */
#define FLASH_PDKEYR      0x04     /*!< FLASH power down key register,            Address offset: 0x04 */
#define FLASH_KEYR        0x08     /*!< FLASH key register,                       Address offset: 0x08 */
#define FLASH_OPTKEYR     0x0C     /*!< FLASH option key register,                Address offset: 0x0C */
#define FLASH_SR          0x10     /*!< FLASH status register,                    Address offset: 0x10 */
#define FLASH_CR          0x14     /*!< FLASH control register,                   Address offset: 0x14 */
#define FLASH_ECCR        0x18     /*!< FLASH ECC register,                       Address offset: 0x18 */
#define FLASH_RESERVED1   0x1C     /*!< Reserved1,                                Address offset: 0x1C */
#define FLASH_OPTR        0x20     /*!< FLASH option register,                    Address offset: 0x20 */
#define FLASH_PCROP1SR    0x24     /*!< FLASH bank1 PCROP start address register, Address offset: 0x24 */
#define FLASH_PCROP1ER    0x28     /*!< FLASH bank1 PCROP end address register,   Address offset: 0x28 */
#define FLASH_WRP1AR      0x2C     /*!< FLASH bank1 WRP area A address register,  Address offset: 0x2C */
#define FLASH_WRP1BR      0x30     /*!< FLASH bank1 WRP area B address register,  Address offset: 0x30 */
#define FLASH_RESERVED2   0x34 	   /*!< Reserved2 is 15 words                     Address offset: 0x34 */
#define FLASH_SEC1R       0x70     /*!< FLASH Securable memory register bank1,    Address offset: 0x70 */


