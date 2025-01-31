--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package Motor_Drivers is

   type Motor_Index is range 1 .. 4;

   procedure Set_Forward (Motor : Motor_Index);

   procedure Set_Backward (Motor : Motor_Index);

   procedure Set_Break (Motor : Motor_Index);

   procedure Set_Off (Motor : Motor_Index);

end Motor_Drivers;
