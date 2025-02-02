--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Motor_Drivers;
with Sensors;

package body Control is

   Desired : A0B.Types.Unsigned_16 := 2_048;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      null;
   end Initialize;

   ---------------
   -- Iteration --
   ---------------

   procedure Iteration is
      use type A0B.Types.Unsigned_16;

      Current : constant A0B.Types.Unsigned_16 := Sensors.Get_Position;

   begin
      if Current < Desired - 10 then
         Motor_Drivers.Set_Forward (1);

      elsif Current > Desired + 10 then
         Motor_Drivers.Set_Backward (1);

      else
         Motor_Drivers.Set_Break (1);
      end if;
   end Iteration;

   ---------
   -- Set --
   ---------

   procedure Set (To : A0B.Types.Unsigned_16) is
   begin
      Desired := To;
   end Set;

end Control;
