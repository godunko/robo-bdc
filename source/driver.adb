--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Configuration;
with Console;
with Motor_Drivers;

procedure Driver is
   Command : Character;

begin
   Configuration.Initialize;

   Console.New_Line;
   Console.Put_Line ("RoboBDC Brushed DC Motors Controller");
   Console.New_Line;

   loop
      Console.Put ("> ");
      Console.Get (Command);

      case Command is
         when 'f' | 'F' =>
            Console.Put_Line ("forward");
            Motor_Drivers.Set_Forward;

         when 'r' | 'R' =>
            Console.Put_Line ("reverse");
            Motor_Drivers.Set_Backward;

         when 'b' | 'B' =>
            Console.Put_Line ("break");
            Motor_Drivers.Set_Break;

         when 'o' | 'O' =>
            Console.Put_Line ("off");
            Motor_Drivers.Set_Off;

         when others =>
            Console.Put_Line ("unknown command");
      end case;
   end loop;
end Driver;
