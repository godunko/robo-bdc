--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Configuration;
with Console;

procedure Driver is
begin
   Configuration.Initialize;

   Console.New_Line;
   Console.Put_Line ("Robo DC Motors Controller");
   Console.New_Line;
end Driver;
