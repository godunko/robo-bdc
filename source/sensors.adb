--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.SVD.ADC;
with A0B.Types;

with Configuration;
with Console;

package body Sensors is

   type Sensors_Data is record
      Vref        : A0B.Types.Unsigned_16;
      M1_Current  : A0B.Types.Unsigned_16;
      M1_Position : A0B.Types.Unsigned_16;
      M2_Current  : A0B.Types.Unsigned_16;
      M2_Position : A0B.Types.Unsigned_16;
      M3_Current  : A0B.Types.Unsigned_16;
      M3_Position : A0B.Types.Unsigned_16;
      M4_Current  : A0B.Types.Unsigned_16;
      M4_Position : A0B.Types.Unsigned_16;
   end record;

   Data : array (1 .. 1_000) of Sensors_Data with Export;

   ------------------
   -- Collect_Data --
   ------------------

   procedure Collect_Data is
      use A0B.STM32F401.SVD.ADC;

      --  function Get return A0B.Types.Unsigned_16;
      --
      --  ---------
      --  -- Get --
      --  ---------
      --
      --  function Get return A0B.Types.Unsigned_16 is
      --  begin
      --     while not ADC1_Periph.SR.EOC loop
      --        null;
      --     end loop;
      --
      --     return ADC1_Periph.DR.DATA;
      --  end Get;

   begin
      Configuration.ADC1_DMA_Stream.Set_Memory_Buffer
        (Memory    => Data'Address,
         Count     => 9_000,
         Increment => True);
      Configuration.ADC1_DMA_Stream.Enable;

      --  for Item of Data loop
      ADC1_Periph.CR2.SWSTART := True;
         --  Item.Vref        := Get;
         --  Item.M1_Current  := Get;
         --  Item.M1_Position := Get;
         --  Item.M2_Current  := Get;
         --  Item.M2_Position := Get;
         --  Item.M3_Current  := Get;
         --  Item.M3_Position := Get;
         --  Item.M4_Current  := Get;
         --  Item.M4_Position := Get;
      --  end loop;
   end Collect_Data;

   ----------
   -- Dump --
   ----------

   procedure Dump is
   begin
      Console.New_Line;
      Console.Put_Line ("Vref");

      for J in Data'Range loop
         if (J - 1) mod 20 = 0 then
            Console.New_Line;
         end if;

         Console.Put (A0B.Types.Unsigned_16'Image (Data (J).Vref));
      end loop;

      Console.New_Line;

      Console.New_Line;
      Console.Put_Line ("M1 current");

      for J in Data'Range loop
         if (J - 1) mod 20 = 0 then
            Console.New_Line;
         end if;

         Console.Put (A0B.Types.Unsigned_16'Image (Data (J).M1_Current));
      end loop;

      Console.New_Line;

      Console.New_Line;
      Console.Put_Line ("M1 position");

      for J in Data'Range loop
         if (J - 1) mod 20 = 0 then
            Console.New_Line;
         end if;

         Console.Put (A0B.Types.Unsigned_16'Image (Data (J).M1_Position));
      end loop;

      Console.New_Line;
   end Dump;

end Sensors;
