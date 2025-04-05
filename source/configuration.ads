--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32_DMA.F1_Channels;
with A0B.STM32_USART.Generic_F0_USARTs.Generic_H7_USART;
with A0B.STM32G4.DMA;
with A0B.STM32G474.DMA.Generic_CH0;
with A0B.STM32G474.DMA.Generic_CH1;
with A0B.STM32G474.DMA.Generic_CH2;
with A0B.STM32G474.GPIO;
with A0B.STM32G474.GPIOA;
--  with A0B.STM32F401.DMA.DMA2.Stream0;
--  with A0B.STM32F401.DMA.DMA2.Stream5;
--  with A0B.STM32F401.GPIO.PIOA;
--  private with A0B.STM32F401.GPIO.PIOB;
--  with A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous;

package Configuration
  with Preelaborate
is

   --  package UART1 is
   --    new A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous
   --    (Receive_Stream => A0B.STM32F401.DMA.DMA2.Stream5.DMA2_Stream5'Access,
   --     TX_Pin         => A0B.STM32F401.GPIO.PIOA.PA9'Access,
   --     RX_Pin         => A0B.STM32F401.GPIO.PIOA.PA10'Access);
   --
   --  ADC1_DMA_Stream : A0B.STM32F401.DMA.DMA_Stream
   --    renames A0B.STM32F401.DMA.DMA2.Stream0.DMA2_Stream0;

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

   package UART_RX_DMA_CH is
     new A0B.STM32G474.DMA.Generic_CH1 (A0B.STM32G4.DMA.USART1_RX);
   package UART_TX_DMA_CH is
     new A0B.STM32G474.DMA.Generic_CH0 (A0B.STM32G4.DMA.USART1_TX);

   package My_F0_USART is
     new A0B.STM32_USART.Generic_F0_USARTs
       (DMA_Data_Item      => A0B.STM32_DMA.DMA_Data_Item,
        Byte               => A0B.STM32_DMA.Byte,
        Word               => A0B.STM32_DMA.Word,
        DMA_Priority_Level => A0B.STM32_DMA.Priority_Level,
        Low                => A0B.STM32_DMA.Low,
        DMA_Channel        => A0B.STM32_DMA.F1_Channels.Abstract_DMA_Channel,
        Initialize         => A0B.STM32_DMA.F1_Channels.Initialize,
        Configure_Peripheral_To_Memory =>
           A0B.STM32_DMA.F1_Channels.Configure_Peripheral_To_Memory,
        Configure_Memory_To_Peripheral =>
           A0B.STM32_DMA.F1_Channels.Configure_Memory_To_Peripheral,
        Set_Memory         => A0B.STM32_DMA.F1_Channels.Set_Memory,
        Set_Transfer_Completed_Callback =>
           A0B.STM32_DMA.F1_Channels.Set_Transfer_Completed_Callback,
        Enable             => A0B.STM32_DMA.F1_Channels.Enable,
        Disable            => A0B.STM32_DMA.F1_Channels.Disable,
        Is_Enabled         => A0B.STM32_DMA.F1_Channels.Is_Enabled,
        Enable_Transfer_Completed_Interrupt =>
           A0B.STM32_DMA.F1_Channels.Enable_Transfer_Completed_Interrupt,
        Get_Masked_And_Clear_Transfer_Completed =>
           A0B.STM32_DMA.F1_Channels.Get_Masked_And_Clear_Transfer_Completed,
        Get_Number_Of_Data_Items =>
           A0B.STM32_DMA.F1_Channels.Get_Number_Of_Items);

   package My_H7_USART is
      new My_F0_USART.Generic_H7_USART;

   Console_UART : My_H7_USART.H7_USART_Controller
     (Peripheral       => My_H7_USART.USART1'Access,
      Receive_Channel  => UART_RX_DMA_CH.DMA_CH'Access,
      Receive_Line     => A0B.STM32G4.DMA.USART1_RX,
      Transmit_Channel => UART_TX_DMA_CH.DMA_CH'Access,
      Transmit_Line    => A0B.STM32G4.DMA.USART1_RX);

   package ADC1_DMA_CH is
     new A0B.STM32G474.DMA.Generic_CH2 (A0B.STM32G4.DMA.ADC1);

private

   --  M1_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB4;  --  TIM3_CH1
   --  M1_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB5;  --  TIM3_CH2
   --  M2_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB0;  --  TIM3_CH3
   --  M2_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB1;  --  TIM3_CH4
   --  M3_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB6;  --  TIM4_CH1
   --  M3_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB7;  --  TIM4_CH2
   --  M4_IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB8;  --  TIM4_CH3
   --  M4_IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB9;  --  TIM4_CH4

   --  M1_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOA.PA0;  --  ADC1_IN0
   M1_P_Pin   : A0B.STM32G474.GPIO.GPIO_EXTI_Line
     renames A0B.STM32G474.GPIOA.PA0;  --  ADC1_IN1
   --  M2_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOA.PA2;  --  ADC1_IN2
   --  M2_P_Pin   : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOA.PA3;  --  ADC1_IN3
   --  M3_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOA.PA4;  --  ADC1_IN4
   --  M3_P_Pin   : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOA.PA5;  --  ADC1_IN5
   --  M4_C_Pin   : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOA.PA6;  --  ADC1_IN6
   --  M4_P_Pin   : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOA.PA7;  --  ADC1_IN7

end Configuration;
