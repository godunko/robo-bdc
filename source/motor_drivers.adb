--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  with A0B.STM32F401.SVD.TIM;
with A0B.Types;

package body Motor_Drivers is

   --  CCR : constant := 2_520;
   CCR : constant := 3_360;

   procedure Set_1
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16);

   procedure Set_2
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16);

   procedure Set_3
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16);

   procedure Set_4
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16);

   -----------
   -- Set_1 --
   -----------

   procedure Set_1
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16)
   is
      --  TIM : A0B.STM32F401.SVD.TIM.TIM3_Peripheral
      --    renames A0B.STM32F401.SVD.TIM.TIM3_Periph;
      --
   begin
      raise Program_Error;
   --     TIM.CCR1.CCR1_L := CCR1;
   --     TIM.CCR2.CCR2_L := CCR2;
   end Set_1;

   -----------
   -- Set_2 --
   -----------

   procedure Set_2
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16)
   is
      --  TIM : A0B.STM32F401.SVD.TIM.TIM3_Peripheral
      --    renames A0B.STM32F401.SVD.TIM.TIM3_Periph;

   begin
      raise Program_Error;
      --  TIM.CCR3.CCR3_L := CCR1;
      --  TIM.CCR4.CCR4_L := CCR2;
   end Set_2;

   -----------
   -- Set_3 --
   -----------

   procedure Set_3
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16)
   is
      --  TIM : A0B.STM32F401.SVD.TIM.TIM3_Peripheral
      --    renames A0B.STM32F401.SVD.TIM.TIM4_Periph;

   begin
      raise Program_Error;
      --  TIM.CCR1.CCR1_L := CCR1;
      --  TIM.CCR2.CCR2_L := CCR2;
   end Set_3;

   -----------
   -- Set_4 --
   -----------

   procedure Set_4
     (CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16)
   is
      --  TIM : A0B.STM32F401.SVD.TIM.TIM3_Peripheral
      --    renames A0B.STM32F401.SVD.TIM.TIM4_Periph;

   begin
      raise Program_Error;
      --  TIM.CCR3.CCR3_L := CCR1;
      --  TIM.CCR4.CCR4_L := CCR2;
   end Set_4;

   ------------------
   -- Set_Backward --
   ------------------

   procedure Set_Backward (Motor : Motor_Index) is
      CCR1 : constant A0B.Types.Unsigned_16 := 0;
      CCR2 : constant A0B.Types.Unsigned_16 := CCR;

   begin
      case Motor is
         when 1 => Set_1 (CCR1, CCR2);
         when 2 => Set_2 (CCR1, CCR2);
         when 3 => Set_3 (CCR1, CCR2);
         when 4 => Set_4 (CCR1, CCR2);
      end case;
   end Set_Backward;

   ---------------
   -- Set_Break --
   ---------------

   procedure Set_Break (Motor : Motor_Index) is
      CCR1 : constant A0B.Types.Unsigned_16 := A0B.Types.Unsigned_16'Last;
      CCR2 : constant A0B.Types.Unsigned_16 := A0B.Types.Unsigned_16'Last;

   begin
      case Motor is
         when 1 => Set_1 (CCR1, CCR2);
         when 2 => Set_2 (CCR1, CCR2);
         when 3 => Set_3 (CCR1, CCR2);
         when 4 => Set_4 (CCR1, CCR2);
      end case;
   end Set_Break;

   -----------------
   -- Set_Forward --
   -----------------

   procedure Set_Forward (Motor : Motor_Index) is
      CCR1 : constant A0B.Types.Unsigned_16 := CCR;
      CCR2 : constant A0B.Types.Unsigned_16 := 0;

   begin
      case Motor is
         when 1 => Set_1 (CCR1, CCR2);
         when 2 => Set_2 (CCR1, CCR2);
         when 3 => Set_3 (CCR1, CCR2);
         when 4 => Set_4 (CCR1, CCR2);
      end case;
   end Set_Forward;

   -------------
   -- Set_Off --
   -------------

   procedure Set_Off (Motor : Motor_Index) is
      CCR1 : constant A0B.Types.Unsigned_16 := 0;
      CCR2 : constant A0B.Types.Unsigned_16 := 0;

   begin
      case Motor is
         when 1 => Set_1 (CCR1, CCR2);
         when 2 => Set_2 (CCR1, CCR2);
         when 3 => Set_3 (CCR1, CCR2);
         when 4 => Set_4 (CCR1, CCR2);
      end case;
   end Set_Off;

end Motor_Drivers;
