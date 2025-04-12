--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.Callbacks.Generic_Parameterless;
--  with A0B.STM32G474.SVD.ADC;

with Configuration;
with Console;
--  with Control;

package body Sensors is

   type ADC1_Sensors_Data is record
      M1_Position     : A0B.Types.Unsigned_16;
      M1_Position_Bad : A0B.Types.Unsigned_16;
      M2_Position     : A0B.Types.Unsigned_16;
      M2_Position_Bad : A0B.Types.Unsigned_16;
      M1_Current      : A0B.Types.Unsigned_16;
      M1_Current_Bad  : A0B.Types.Unsigned_16;
   end record;

   type ADC2_Sensors_Data is record
      M3_Position     : A0B.Types.Unsigned_16;
      M3_Position_Bad : A0B.Types.Unsigned_16;
      M2_Current      : A0B.Types.Unsigned_16;
      M2_Current_Bad  : A0B.Types.Unsigned_16;
      M3_Current      : A0B.Types.Unsigned_16;
      M3_Current_Bad  : A0B.Types.Unsigned_16;
   end record;

   ADC1_Channels : constant := 6;
   ADC2_Channels : constant := 6;

   type Buffer_1_Array is array (Positive range <>) of ADC1_Sensors_Data;

   type Buffer_2_Array is array (Positive range <>) of ADC2_Sensors_Data;

   Buffer_1 : Buffer_1_Array (1 .. 120) with Export;
   Buffer_2 : Buffer_2_Array (1 .. 120) with Export;
   --  Buffers to receive data with DNA.

   --  Data   : Buffer_Array (1 .. 2_400) with Export;
   Last   : Natural := 0;
   --  Buffer to accumulate data.

   --  Current : Sensors_Data;
   Average_Position : A0B.Types.Unsigned_16;

   procedure On_Conversion_Done;

   package On_Conversion_Done_Callbacks is
      new A0B.Callbacks.Generic_Parameterless (On_Conversion_Done);

   ------------------
   -- Collect_Data --
   ------------------

   procedure Collect_Data is
   begin
      Last := 0;
   end Collect_Data;

   ----------
   -- Dump --
   ----------

   procedure Dump is

      procedure Put (Item : A0B.Types.Unsigned_16) is
         Image  : constant String := A0B.Types.Unsigned_16'Image (Item);
         Buffer : String (1 .. 5) := [others => ' '];

      begin
         Buffer (Buffer'Last - Image'Length + 1 .. Buffer'Last) := Image;
         Console.Put (Buffer);
      end Put;

   begin
      --  Console.New_Line;
      --  Console.Put_Line ("Vref");
      --
      --  for J in Data'Range loop
      --     if (J - 1) mod 30 = 0 then
      --        Console.New_Line;
      --     elsif (J - 1) mod 6 = 0 then
      --        Console.Put ("  ");
      --     end if;
      --
      --     Put (Data (J).Vref);
      --  end loop;
      --
      --  Console.New_Line;

      Console.New_Line;
      Console.Put_Line ("M1 current");

      --  for J in Data'Range loop
      --     if (J - 1) mod 30 = 0 then
      --        Console.New_Line;
      --     elsif (J - 1) mod 6 = 0 then
      --        Console.Put ("  ");
      --     end if;
      --
      --     Put (Data (J).M1_Current);
      --  end loop;

      Console.New_Line;

      Console.New_Line;
      Console.Put_Line ("M1 position");

      --  for J in Data'Range loop
      --     if (J - 1) mod 30 = 0 then
      --        Console.New_Line;
      --     elsif (J - 1) mod 6 = 0 then
      --        Console.Put ("  ");
      --     end if;
      --
      --     Put (Data (J).M1_Position);
      --  end loop;

      Console.New_Line;
   end Dump;

   ------------------
   -- Get_Position --
   ------------------

   function Get_Position return A0B.Types.Unsigned_16 is
   begin
      return Average_Position;
      --  return Current.M1_Position;
   end Get_Position;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use type A0B.Types.Unsigned_16;

   begin
      Configuration.ADC1_DMA_CH.DMA_CH.Set_Interrupt_Callback
        (On_Conversion_Done_Callbacks.Create_Callback);
      Configuration.ADC1_DMA_CH.DMA_CH.Set_Memory
        (Memory_Address  => Buffer_1'Address,
         Number_Of_Items => Buffer_1'Length * ADC1_Channels);

      Configuration.ADC2_DMA_CH.DMA_CH.Set_Interrupt_Callback
        (On_Conversion_Done_Callbacks.Create_Callback);
      Configuration.ADC2_DMA_CH.DMA_CH.Set_Memory
        (Memory_Address  => Buffer_2'Address,
         Number_Of_Items => Buffer_2'Length * ADC2_Channels);

      null;

      Configuration.ADC1_DMA_CH.DMA_CH.Enable;
      Configuration.ADC2_DMA_CH.DMA_CH.Enable;

      --  Configuration.ADC1_DMA_Stream.Set_Memory_Buffer
      --    (Memory    => Buffer'Address,
      --     Count     => Buffer'Length * 9,
      --     Increment => True);
      --  Configuration.ADC1_DMA_Stream.Enable;
      --  Configuration.ADC1_DMA_Stream.Set_Interrupt_Callback
      --    (On_Conversion_Done_Callbacks.Create_Callback);
      --  Configuration.ADC1_DMA_Stream.Enable_Half_Transfer_Interrupt;
      --  Configuration.ADC1_DMA_Stream.Enable_Transfer_Complete_Interrupt;
   end Initialize;

   ------------------------
   -- On_Conversion_Done --
   ------------------------

   procedure On_Conversion_Done is
      --  F : Positive;
      --  L : Positive;

   begin
      Configuration.ADC1_DMA_CH.DMA_CH.Disable;
      Configuration.ADC2_DMA_CH.DMA_CH.Disable;

      raise Program_Error;
      --  if Configuration.ADC1_DMA_Stream.Get_Masked_And_Clear_Half_Transfer then
      --     if Last <= Data'Last - Buffer'Length / 2 then
      --        F := Buffer'First;
      --        L := Buffer'Length / 2;
      --
      --        Data (Last + 1 .. Last + Buffer'Length / 2) :=
      --          Buffer (Buffer'First .. Buffer'Length / 2);
      --        Last := @ + Buffer'Length / 2;
      --     end if;
      --
      --     Current := Buffer (Buffer'Length / 2);
      --  end if;
      --
      --  if Configuration.ADC1_DMA_Stream.Get_Masked_And_Clear_Transfer_Completed
      --  then
      --     F := Buffer'First;
      --     L := Buffer'Length / 2;
      --
      --     if Last <= Data'Last - Buffer'Length / 2 then
      --        Data (Last + 1 .. Last + Buffer'Length / 2) :=
      --          Buffer (Buffer'First + Buffer'Length / 2 .. Buffer'Last);
      --        Last := @ + Buffer'Length / 2;
      --     end if;
      --
      --     Current := Buffer (Buffer'Last);
      --  end if;
      --
      --  declare
      --     use type A0B.Types.Unsigned_32;
      --
      --     A : A0B.Types.Unsigned_32 := 0;
      --
      --  begin
      --     for J in F .. L loop
      --        A := @ + A0B.Types.Unsigned_32 (Buffer (J).M1_Position);
      --     end loop;
      --
      --     Average_Position :=
      --       A0B.Types.Unsigned_16 (A / A0B.Types.Unsigned_32 (L - F + 1));
      --  end;
      --
      --  Control.Iteration;
      null;
   end On_Conversion_Done;

end Sensors;
