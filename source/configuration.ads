--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.DMA.DMA2.Stream5;
with A0B.STM32F401.GPIO.PIOA;
private with A0B.STM32F401.GPIO.PIOB;
with A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous;

package Configuration
  with Preelaborate
is

   package UART1 is
     new A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous
     (Receive_Stream => A0B.STM32F401.DMA.DMA2.Stream5.DMA2_Stream5'Access,
      TX_Pin         => A0B.STM32F401.GPIO.PIOA.PA9'Access,
      RX_Pin         => A0B.STM32F401.GPIO.PIOA.PA10'Access);

   procedure Initialize;
   --  Initialize peripherals:
   --    - UART1 for console
   --    - TIM3 timer for PWM

private

   M1_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB4;  --  TIM3_CH1
   M1_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB5;  --  TIM3_CH2
   M2_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB0;  --  TIM3_CH3
   M2_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB1;  --  TIM3_CH4
   M3_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB6;  --  TIM4_CH1
   M3_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB7;  --  TIM4_CH2
   M4_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB8;  --  TIM4_CH3
   M4_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB9;  --  TIM4_CH4

end Configuration;
