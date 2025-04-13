--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  STM32G474

pragma Ada_2022;

package A0B.STM32.TIM_Lines
  with Preelaborate, No_Elaboration_Code_All
is

   TIM2_CH1   : constant Function_Line_Descriptor;
   TIM2_CH2   : constant Function_Line_Descriptor;
   TIM2_CH3   : constant Function_Line_Descriptor;
   TIM2_CH4   : constant Function_Line_Descriptor;
   TIM2_ETR   : constant Function_Line_Descriptor;

   TIM3_CH1   : constant Function_Line_Descriptor;
   TIM3_CH2   : constant Function_Line_Descriptor;
   TIM3_CH3   : constant Function_Line_Descriptor;
   TIM3_CH4   : constant Function_Line_Descriptor;
   TIM3_ETR   : constant Function_Line_Descriptor;

   TIM4_CH1   : constant Function_Line_Descriptor;
   TIM4_CH2   : constant Function_Line_Descriptor;
   TIM4_CH3   : constant Function_Line_Descriptor;
   TIM4_CH4   : constant Function_Line_Descriptor;
   TIM4_ETR   : constant Function_Line_Descriptor;

   TIM15_CH1  : constant Function_Line_Descriptor;
   TIM15_CH1N : constant Function_Line_Descriptor;
   TIM15_CH2  : constant Function_Line_Descriptor;
   TIM15_BKIN : constant Function_Line_Descriptor;

private

   TIM2_CH1  : constant Function_Line_Descriptor :=
     [(A, 0, 1), (A, 5, 1), (A, 15, 1), (D, 3, 2)];
   TIM2_CH2  : constant Function_Line_Descriptor :=
     [(A, 1, 1), (B, 3, 1), (D, 4, 2)];
   TIM2_CH3  : constant Function_Line_Descriptor :=
     [(A, 2, 1), (A, 9, 10), (B, 10, 1), (D, 7, 2)];
   TIM2_CH4  : constant Function_Line_Descriptor :=
     [(A, 3, 1), (A, 10, 10), (B, 11, 1), (D, 6, 2)];
   TIM2_ETR  : constant Function_Line_Descriptor :=
     [(A, 0, 14), (A, 5, 2), (A, 15, 14), (D, 3, 2)];

   TIM3_CH1  : constant Function_Line_Descriptor :=
     [(A, 6, 2), (B, 4, 2), (C, 6, 2), (E, 2, 2)];
   TIM3_CH2  : constant Function_Line_Descriptor :=
     [(A, 4, 2), (A, 7, 2), (B, 5, 2), (C, 7, 2), (E, 3, 2)];
   TIM3_CH3  : constant Function_Line_Descriptor :=
     [(B, 0, 2), (C, 8, 2), (E, 4, 2)];
   TIM3_CH4  : constant Function_Line_Descriptor :=
     [(B, 1, 4), (B, 7, 10), (C, 9, 2), (E, 5, 2)];
   TIM3_ETR  : constant Function_Line_Descriptor :=
     [(B, 3, 10), (D, 2, 2)];

   TIM4_CH1  : constant Function_Line_Descriptor :=
     [(A, 11, 10), (B, 6, 2), (D, 12, 2)];
   TIM4_CH2  : constant Function_Line_Descriptor :=
     [(A, 12, 10), (B, 7, 2), (D, 13, 2)];
   TIM4_CH3  : constant Function_Line_Descriptor :=
     [(A, 13, 10), (B, 8, 2), (D, 14, 2)];
   TIM4_CH4  : constant Function_Line_Descriptor :=
     [(B, 9, 2), (D, 15, 2), (F, 6, 2)];
   TIM4_ETR  : constant Function_Line_Descriptor :=
     [(A, 8, 10), (B, 3, 2), (E, 0, 2)];

   TIM15_CH1  : constant Function_Line_Descriptor :=
     [(A, 2, 9), (B, 14, 1), (F, 9, 3)];
   TIM15_CH1N : constant Function_Line_Descriptor :=
     [(A, 1, 9), (B, 15, 2), (G, 9, 14)];
   TIM15_CH2  : constant Function_Line_Descriptor :=
     [(A, 3, 9), (B, 15, 1), (F, 10, 3)];
   TIM15_BKIN : constant Function_Line_Descriptor :=
     [(A, 9, 9), (C, 5, 2)];

end A0B.STM32.TIM_Lines;
