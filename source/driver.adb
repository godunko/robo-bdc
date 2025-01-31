--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Configuration;
with Console;
with Motor_Drivers;

procedure Driver is
   Motor   : Motor_Drivers.Motor_Index := 1;
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
         when '1' =>
            Console.Put_Line ("Motor 1 selected");
            Motor := 1;

         when '2' =>
            Console.Put_Line ("Motor 2 selected");
            Motor := 2;

         when '3' =>
            Console.Put_Line ("Motor 3 selected");
            Motor := 3;

         when '4' =>
            Console.Put_Line ("Motor 4 selected");
            Motor := 4;

         when 'f' | 'F' =>
            Console.Put_Line ("forward");
            Motor_Drivers.Set_Forward (Motor);

         when 'r' | 'R' =>
            Console.Put_Line ("reverse");
            Motor_Drivers.Set_Backward (Motor);

         when 'b' | 'B' =>
            Console.Put_Line ("break");
            Motor_Drivers.Set_Break (Motor);

         when 'o' | 'O' =>
            Console.Put_Line ("off");
            Motor_Drivers.Set_Off (Motor);

         when others =>
            Console.Put_Line ("unknown command");
      end case;
   end loop;
end Driver;
