--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

package Sensors is

   procedure Collect_Data;

   procedure Dump;

   procedure Initialize;

   function Get_Position return A0B.Types.Unsigned_16;

end Sensors;
