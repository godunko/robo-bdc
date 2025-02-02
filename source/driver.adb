--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.Types;

with Configuration;
with Console;
with Control;
with Sensors;

procedure Driver is
   use type A0B.Types.Unsigned_16;

   Command : Character;
   Desired : A0B.Types.Unsigned_16 := 2_048;

begin
   Configuration.Initialize;
   Sensors.Initialize;
   Control.Initialize;
   Configuration.Enable_Timers;

   Console.New_Line;
   Console.Put_Line ("RoboBDC Brushed DC Motors Controller");
   Console.New_Line;

   loop
      Console.Put ("> ");
      Console.Get (Command);

      case Command is
         when 'a' | 'A' =>
            Console.Put_Line ("collect sensors data");
            Sensors.Collect_Data;
            Sensors.Dump;

         when '-' | '_' =>
            Desired := @ - 16;
            Control.Set (Desired);
            Console.Put_Line (A0B.Types.Unsigned_16'Image (Desired));

         when '=' | '+' =>
            Desired := @ + 16;
            Control.Set (Desired);
            Console.Put_Line (A0B.Types.Unsigned_16'Image (Desired));

         when others =>
            Console.Put_Line ("unknown command");
      end case;
   end loop;
end Driver;
