--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.SVD.TIM;
with A0B.Types;

package body Motor_Drivers is

   CCR : constant := 2_520;

   TIM : A0B.STM32F401.SVD.TIM.TIM3_Peripheral
     renames A0B.STM32F401.SVD.TIM.TIM3_Periph;

   ------------------
   -- Set_Backward --
   ------------------

   procedure Set_Backward is
   begin
      TIM.CCR1.CCR1_L := 0;
      TIM.CCR2.CCR2_L := CCR;
   end Set_Backward;

   ---------------
   -- Set_Break --
   ---------------

   procedure Set_Break is
   begin
      TIM.CCR1.CCR1_L := A0B.Types.Unsigned_16'Last;
      TIM.CCR2.CCR2_L := A0B.Types.Unsigned_16'Last;
   end Set_Break;

   -----------------
   -- Set_Forward --
   -----------------

   procedure Set_Forward is
   begin
      TIM.CCR1.CCR1_L := CCR;
      TIM.CCR2.CCR2_L := 0;
   end Set_Forward;

   -------------
   -- Set_Off --
   -------------

   procedure Set_Off is
   begin
      TIM.CCR1.CCR1_L := 0;
      TIM.CCR2.CCR2_L := 0;
   end Set_Off;

end Motor_Drivers;
