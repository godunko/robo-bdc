--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.Time.Clock;
with A0B.Types;

with Ada;
with Ada.Numerics;
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
         --  when 'a' | 'A' =>
         --     Console.Put_Line ("collect sensors data");
         --     Sensors.Collect_Data;
         --     Sensors.Dump;
         --
         --  when '-' | '_' =>
         --     Desired := @ - 32;
         --     Control.Set (Desired);
         --     Console.Put_Line (A0B.Types.Unsigned_16'Image (Desired));
         --
         --  when '=' | '+' =>
         --     Desired := @ + 32;
         --     Control.Set (Desired);
         --     Sensors.Collect_Data;
         --     Console.Put_Line (A0B.Types.Unsigned_16'Image (Desired));
         --     Sensors.Dump;
         --
         --  when 't' | 'T' =>
         --     Desired := 128;
         --     Control.Set (Desired);
         --
         --     while Sensors.Get_Position not in Desired - 8 .. Desired + 8 loop
         --        null;
         --     end loop;
         --
         --     declare
         --        use type A0B.Time.Monotonic_Time;
         --
         --        Started  : constant A0B.Time.Monotonic_Time := A0B.Time.Clock;
         --        Finished : A0B.Time.Monotonic_Time;
         --        Span     : A0B.Time.Time_Span;
         --
         --     begin
         --        Desired := 4096 - 128;
         --        Control.Set (Desired);
         --
         --        while Sensors.Get_Position not in Desired - 8 .. Desired + 8
         --        loop
         --           null;
         --        end loop;
         --
         --        Finished := A0B.Time.Clock;
         --
         --        Span := Finished - Started;
         --
         --        Console.Put_Line
         --          ("rotation time"
         --             & A0B.Types.Integer_64'Image
         --                 (A0B.Time.To_Nanoseconds (Span)));
         --
         --        declare
         --           Time  : constant Float :=
         --             Float (A0B.Time.To_Nanoseconds (Span)) / 1_000_000_000.0;
         --           Speed : constant Float := Ada.Numerics.Pi / Time;
         --
         --        begin
         --           Console.Put_Line
         --             ("rotation time " & Float'Image (Time));
         --           Console.Put_Line
         --             ("rotation speed" & Float'Image (Speed));
         --        end;
         --     end;

         when others =>
            Console.Put_Line ("unknown command");
      end case;
   end loop;
end Driver;
