//@;stm2G491xx_RCC.h wmh 2024-09-21 : RCC register constants extracted from stm2G491xx (updated)
// this version restores the 'U' in USART and probably several other places where a careless global edit deleted it. 
 
#include "stm32g491xx_defines.h"	
#define RCC_limit 0xA0				/* used in 'snapshots02.c', I forget what that's for */
//offsets in RCC struct
#define RCC_CR           0x00        /*!< RCC clock control register,                                              Address offset: 0x00 */
#define RCC_ICSCR        0x04        /*!< RCC internal clock sources calibration register,                         Address offset: 0x04 */
#define RCC_CFGR         0x08        /*!< RCC clock configuration register,                                        Address offset: 0x08 */
#define RCC_PLLCFGR      0x0C        /*!< RCC system PLL configuration register,                                   Address offset: 0x0C */
#define RCC_RESERVED0    0x10        /*!< Reserved,                                                                Address offset: 0x10 */
#define RCC_RESERVED1    0x14        /*!< Reserved,                                                                Address offset: 0x14 */
#define RCC_CIER         0x18        /*!< RCC clock interrupt enable register,                                     Address offset: 0x18 */
#define RCC_CIFR         0x1C        /*!< RCC clock interrupt flag register,                                       Address offset: 0x1C */
#define RCC_CICR         0x20        /*!< RCC clock interrupt clear register,                                      Address offset: 0x20 */
#define RCC_RESERVED2    0x24        /*!< Reserved,                                                                Address offset: 0x24 */
#define RCC_AHB1RSTR     0x28        /*!< RCC AHB1 peripheral reset register,                                      Address offset: 0x28 */
#define RCC_AHB2RSTR     0x2C        /*!< RCC AHB2 peripheral reset register,                                      Address offset: 0x2C */
#define RCC_AHB3RSTR     0x30        /*!< RCC AHB3 peripheral reset register,                                      Address offset: 0x30 */
#define RCC_RESERVED3    0x34        /*!< Reserved,                                                                Address offset: 0x34 */
#define RCC_APB1RSTR1    0x38        /*!< RCC APB1 peripheral reset register 1,                                    Address offset: 0x38 */
#define RCC_APB1RSTR2    0x3C        /*!< RCC APB1 peripheral reset register 2,                                    Address offset: 0x3C */
#define RCC_APB2RSTR     0x40        /*!< RCC APB2 peripheral reset register,                                      Address offset: 0x40 */
#define RCC_RESERVED4    0x44        /*!< Reserved,                                                                Address offset: 0x44 */
#define RCC_AHB1ENR      0x48        /*!< RCC AHB1 peripheral clocks enable register,                              Address offset: 0x48 */
#define RCC_AHB2ENR      0x4C        /*!< RCC AHB2 peripheral clocks enable register,                              Address offset: 0x4C */
#define RCC_AHB3ENR      0x50        /*!< RCC AHB3 peripheral clocks enable register,                              Address offset: 0x50 */
#define RCC_RESERVED5    0x54        /*!< Reserved,                                                                Address offset: 0x54 */
#define RCC_APB1ENR1     0x58        /*!< RCC APB1 peripheral clocks enable register 1,                            Address offset: 0x58 */
#define RCC_APB1ENR2     0x5C        /*!< RCC APB1 peripheral clocks enable register 2,                            Address offset: 0x5C */
#define RCC_APB2ENR      0x60        /*!< RCC APB2 peripheral clocks enable register,                              Address offset: 0x60 */
#define RCC_RESERVED6    0x64        /*!< Reserved,                                                                Address offset: 0x64 */
#define RCC_AHB1SMENR    0x68        /*!< RCC AHB1 peripheral clocks enable in sleep and stop modes register,      Address offset: 0x68 */
#define RCC_AHB2SMENR    0x6C        /*!< RCC AHB2 peripheral clocks enable in sleep and stop modes register,      Address offset: 0x6C */
#define RCC_AHB3SMENR    0x70        /*!< RCC AHB3 peripheral clocks enable in sleep and stop modes register,      Address offset: 0x70 */
#define RCC_RESERVED7    0x74        /*!< Reserved,                                                                Address offset: 0x74 */
#define RCC_APB1SMENR1   0x78        /*!< RCC APB1 peripheral clocks enable in sleep mode,  stop modes register 1, Address offset: 0x78 */
#define RCC_APB1SMENR2   0x7C        /*!< RCC APB1 peripheral clocks enable in sleep mode,  stop modes register 2, Address offset: 0x7C */
#define RCC_APB2SMENR    0x80        /*!< RCC APB2 peripheral clocks enable in sleep mode and stop modes register, Address offset: 0x80 */
#define RCC_RESERVED8    0x84        /*!< Reserved,                                                                Address offset: 0x84 */
#define RCC_CCIPR        0x88        /*!< RCC peripherals independent clock configuration register,                Address offset: 0x88 */
#define RCC_RESERVED9    0x8C        /*!< Reserved,                                                                Address offset: 0x8C */
#define RCC_BDCR         0x90        /*!< RCC backup domain control register,                                      Address offset: 0x90 */
#define RCC_CSR          0x94        /*!< RCC clock control & status register,                                     Address offset: 0x94 */
#define RCC_CRRCR        0x98        /*!< RCC clock recovery RC register,                                          Address offset: 0x98 */
#define RCC_CCIPR2       0x9C        /*!< RCC peripherals independent clock configuration register 2,              Address offset: 0x9C */

#define RCC_HSI48_SPPORT
#define RCC_PLLP_DIV_2_31_SPPORT

//#define RCC_regnames "RCC_CR","RCC_ICSCR","RCC_CFGR","RCC_PLLCFGR","RCC_RESERVED0","RCC_RESERVED1","RCC_CIER","RCC_CIFR","RCC_CICR","RCC_RESERVED2","RCC_AHB1RSTR","RCC_AHB2RSTR","RCC_AHB3RSTR","RCC_RESERVED3","RCC_APB1RSTR1","RCC_APB1RSTR2","RCC_APB2RSTR","RCC_RESERVED4","RCC_AHB1ENR","RCC_AHB2ENR","RCC_AHB3ENR","RCC_RESERVED5","RCC_APB1ENR1","RCC_APB1ENR2","RCC_APB2ENR","RCC_RESERVED6","RCC_AHB1SMENR","RCC_AHB2SMENR","RCC_AHB3SMENR","RCC_RESERVED7","RCC_APB1SMENR1","RCC_APB1SMENR2","RCC_APB2SMENR","RCC_RESERVED8","RCC_CCIPR","RCC_RESERVED9","RCC_BDCR","RCC_CSR","RCC_CRRCR","RCC_CCIPR2"
//It's easy (2 minutes) to build an array of register names such as above. In np++ you do an alt-copy into of just the column of names into
// a new text, then do a global replace of newlines with quote-comma-quote (","), add a quote at the beginning adnn another at the end, 
// and the array of strings pf register names is done.

#ifdef USING_C
#define __IO volatile	// done here to avoid bringing in all the cruft
typedef struct
{
  __IO uint32_t CR;          /*!< RCC clock control register,                                              Address offset: 0x00 */
  __IO uint32_t ICSCR;       /*!< RCC internal clock sources calibration register,                         Address offset: 0x04 */
  __IO uint32_t CFGR;        /*!< RCC clock configuration register,                                        Address offset: 0x08 */
  __IO uint32_t PLLCFGR;     /*!< RCC system PLL configuration register,                                   Address offset: 0x0C */
  uint32_t      RESERVED0;   /*!< Reserved,                                                                Address offset: 0x10 */
  uint32_t      RESERVED1;   /*!< Reserved,                                                                Address offset: 0x14 */
  __IO uint32_t CIER;        /*!< RCC clock interrupt enable register,                                     Address offset: 0x18 */
  __IO uint32_t CIFR;        /*!< RCC clock interrupt flag register,                                       Address offset: 0x1C */
  __IO uint32_t CICR;        /*!< RCC clock interrupt clear register,                                      Address offset: 0x20 */
  uint32_t      RESERVED2;   /*!< Reserved,                                                                Address offset: 0x24 */
  __IO uint32_t AHB1RSTR;    /*!< RCC AHB1 peripheral reset register,                                      Address offset: 0x28 */
  __IO uint32_t AHB2RSTR;    /*!< RCC AHB2 peripheral reset register,                                      Address offset: 0x2C */
  __IO uint32_t AHB3RSTR;    /*!< RCC AHB3 peripheral reset register,                                      Address offset: 0x30 */
  uint32_t      RESERVED3;   /*!< Reserved,                                                                Address offset: 0x34 */
  __IO uint32_t APB1RSTR1;   /*!< RCC APB1 peripheral reset register 1,                                    Address offset: 0x38 */
  __IO uint32_t APB1RSTR2;   /*!< RCC APB1 peripheral reset register 2,                                    Address offset: 0x3C */
  __IO uint32_t APB2RSTR;    /*!< RCC APB2 peripheral reset register,                                      Address offset: 0x40 */
  uint32_t      RESERVED4;   /*!< Reserved,                                                                Address offset: 0x44 */
  __IO uint32_t AHB1ENR;     /*!< RCC AHB1 peripheral clocks enable register,                              Address offset: 0x48 */
  __IO uint32_t AHB2ENR;     /*!< RCC AHB2 peripheral clocks enable register,                              Address offset: 0x4C */
  __IO uint32_t AHB3ENR;     /*!< RCC AHB3 peripheral clocks enable register,                              Address offset: 0x50 */
  uint32_t      RESERVED5;   /*!< Reserved,                                                                Address offset: 0x54 */
  __IO uint32_t APB1ENR1;    /*!< RCC APB1 peripheral clocks enable register 1,                            Address offset: 0x58 */
  __IO uint32_t APB1ENR2;    /*!< RCC APB1 peripheral clocks enable register 2,                            Address offset: 0x5C */
  __IO uint32_t APB2ENR;     /*!< RCC APB2 peripheral clocks enable register,                              Address offset: 0x60 */
  uint32_t      RESERVED6;   /*!< Reserved,                                                                Address offset: 0x64 */
  __IO uint32_t AHB1SMENR;   /*!< RCC AHB1 peripheral clocks enable in sleep and stop modes register,      Address offset: 0x68 */
  __IO uint32_t AHB2SMENR;   /*!< RCC AHB2 peripheral clocks enable in sleep and stop modes register,      Address offset: 0x6C */
  __IO uint32_t AHB3SMENR;   /*!< RCC AHB3 peripheral clocks enable in sleep and stop modes register,      Address offset: 0x70 */
  uint32_t      RESERVED7;   /*!< Reserved,                                                                Address offset: 0x74 */
  __IO uint32_t APB1SMENR1;  /*!< RCC APB1 peripheral clocks enable in sleep mode and stop modes register 1, Address offset: 0x78 */
  __IO uint32_t APB1SMENR2;  /*!< RCC APB1 peripheral clocks enable in sleep mode and stop modes register 2, Address offset: 0x7C */
  __IO uint32_t APB2SMENR;   /*!< RCC APB2 peripheral clocks enable in sleep mode and stop modes register, Address offset: 0x80 */
  uint32_t      RESERVED8;   /*!< Reserved,                                                                Address offset: 0x84 */
  __IO uint32_t CCIPR;       /*!< RCC peripherals independent clock configuration register,                Address offset: 0x88 */
  uint32_t      RESERVED9;   /*!< Reserved,                                                                Address offset: 0x8C */
  __IO uint32_t BDCR;        /*!< RCC backup domain control register,                                      Address offset: 0x90 */
  __IO uint32_t CSR;         /*!< RCC clock control & status register,                                     Address offset: 0x94 */
  __IO uint32_t CRRCR;       /*!< RCC clock recovery RC register,                                          Address offset: 0x98 */
  __IO uint32_t CCIPR2;      /*!< RCC peripherals independent clock configuration register 2,              Address offset: 0x9C */
} RCC_TypeDef;

#endif

