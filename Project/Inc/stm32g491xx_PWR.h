//stm32g491xx_PWR.h wmh 2024-09-21 :  PWR register offsets extracted from stm2G491xx.h

#include "stm32g491xx_defines.h"	

//offsets in PWR register struct
#define PWR_CR1               0x00     /*!< PWR power control register 1,        Address offset: 0x00 */
#define PWR_CR2               0x04     /*!< PWR power control register 2,        Address offset: 0x04 */
#define PWR_CR3               0x08     /*!< PWR power control register 3,        Address offset: 0x08 */
#define PWR_CR4               0x0C     /*!< PWR power control register 4,        Address offset: 0x0C */
#define PWR_SR1               0x10     /*!< PWR power status register 1,         Address offset: 0x10 */
#define PWR_SR2               0x14     /*!< PWR power status register 2,         Address offset: 0x14 */
#define PWR_SCR               0x18     /*!< PWR power status reset register,     Address offset: 0x18 */
#define PWR_RESERVED1     0x1C     /*!< Reserved,                            Address offset: 0x1C */
#define PWR_PUCRA             0x20     /*!< Pull_up control register of portA,   Address offset: 0x20 */
#define PWR_PDCRA             0x24     /*!< Pull_Down control register of portA, Address offset: 0x24 */
#define PWR_PUCRB             0x28     /*!< Pull_up control register of portB,   Address offset: 0x28 */
#define PWR_PDCRB             0x2C     /*!< Pull_Down control register of portB, Address offset: 0x2C */
#define PWR_PUCRC             0x30     /*!< Pull_up control register of portC,   Address offset: 0x30 */
#define PWR_PDCRC             0x34     /*!< Pull_Down control register of portC, Address offset: 0x34 */
#define PWR_PUCRD             0x38     /*!< Pull_up control register of portD,   Address offset: 0x38 */
#define PWR_PDCRD             0x3C     /*!< Pull_Down control register of portD, Address offset: 0x3C */
#define PWR_PUCRE             0x40     /*!< Pull_up control register of portE,   Address offset: 0x40 */
#define PWR_PDCRE             0x44     /*!< Pull_Down control register of portE, Address offset: 0x44 */
#define PWR_PUCRF             0x48     /*!< Pull_up control register of portF,   Address offset: 0x48 */
#define PWR_PDCRF             0x4C     /*!< Pull_Down control register of portF, Address offset: 0x4C */
#define PWR_PUCRG             0x50     /*!< Pull_up control register of portG,   Address offset: 0x50 */
#define PWR_PDCRG             0x54     /*!< Pull_Down control register of portG, Address offset: 0x54 */
#define PWR_RESERVED2     0x58     /*!< Reserved  10 words                   Address offset: 0x58 - 0x7C */
#define PWR_CR5               0x80     /*!< PWR power control register 5,        Address offset: 0x80 */

//missing here is C struct for the above