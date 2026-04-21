//@; stm2G491xx_USARTn.h wmh 2024-09-21 : USART register offsets extracted from stm2G491xx.h

#include "stm32g491xx_defines.h"	

//offsets in USART register struct
#define USART_CR1    0x00      /*!< USART Control register 1,                 Address offset: 0x00  */
#define USART_CR2    0x04      /*!< USART Control register 2,                 Address offset: 0x04  */
#define USART_CR3    0x08      /*!< USART Control register 3,                 Address offset: 0x08  */
#define USART_BRR    0x0C      /*!< USART Baud rate register,                 Address offset: 0x0C  */
#define USART_GTPR   0x10      /*!< USART Guard time and prescaler register,  Address offset: 0x10  */
#define USART_RTOR   0x14      /*!< USART Receiver Timeout register,          Address offset: 0x14  */
#define USART_RQR    0x18      /*!< USART Request register,                   Address offset: 0x18  */
#define USART_ISR    0x1C      /*!< USART Interrupt and status register,      Address offset: 0x1C  */
#define USART_ICR    0x20      /*!< USART Interrupt flag Clear register,      Address offset: 0x20  */
#define USART_RDR    0x24      /*!< USART Receive Data register,              Address offset: 0x24  */
#define USART_TDR    0x28      /*!< USART Transmit Data register,             Address offset: 0x28  */
#define USART_PRESC  0x2C      /*!< USART Prescaler register,                 Address offset: 0x2C  */

#ifdef USING_C 
#define __IO volatile	// done here to avoid bringing in all the cruft
typedef struct
{
  __IO uint32_t CR1;         /*!< USART Control register 1,                 Address offset: 0x00  */
  __IO uint32_t CR2;         /*!< USART Control register 2,                 Address offset: 0x04  */
  __IO uint32_t CR3;         /*!< USART Control register 3,                 Address offset: 0x08  */
  __IO uint32_t BRR;         /*!< USART Baud rate register,                 Address offset: 0x0C  */
  __IO uint32_t GTPR;        /*!< USART Guard time and prescaler register,  Address offset: 0x10  */
  __IO uint32_t RTOR;        /*!< USART Receiver Timeout register,          Address offset: 0x14  */
  __IO uint32_t RQR;         /*!< USART Request register,                   Address offset: 0x18  */
  __IO uint32_t ISR;         /*!< USART Interrupt and status register,      Address offset: 0x1C  */
  __IO uint32_t ICR;         /*!< USART Interrupt flag Clear register,      Address offset: 0x20  */
  __IO uint32_t RDR;         /*!< USART Receive Data register,              Address offset: 0x24  */
  __IO uint32_t TDR;         /*!< USART Transmit Data register,             Address offset: 0x28  */
  __IO uint32_t PRESC;       /*!< USART Prescaler register,                 Address offset: 0x2C  */
} USART_TypeDef;
#endif

