--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.DMA.DMA2.Stream0;
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

   ADC1_DMA_Stream : A0B.STM32F401.DMA.DMA_Stream
     renames A0B.STM32F401.DMA.DMA2.Stream0.DMA2_Stream0;

   procedure Initialize;
   --  Initialize peripherals:
   --    - GPIO
   --    - DMA2 Stream0 for ADC
   --    - ADC1
   --    - TIM3/TIM4 timer for PWM
   --    - UART1 for console
   --
   --  All timers are disabled to be able to complete setup of ADC data.

   procedure Enable_Timers;
   --  Enable all timers.

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

   M1_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA0;  --  ADC1_IN0
   M1_P_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA1;  --  ADC1_IN1
   M2_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA2;  --  ADC1_IN2
   M2_P_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA3;  --  ADC1_IN3
   M3_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA4;  --  ADC1_IN4
   M3_P_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA5;  --  ADC1_IN5
   M4_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA6;  --  ADC1_IN6
   M4_P_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA7;  --  ADC1_IN7

end Configuration;
