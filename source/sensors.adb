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

   ADC1_Buffer : Buffer_1_Array (1 .. 120) with Export;
   ADC2_Buffer : Buffer_2_Array (1 .. 120) with Export;
   --  Buffers to receive data with DNA.

   type Sensors_Data is record
      M1_Position : A0B.Types.Unsigned_16;
      M1_Current  : A0B.Types.Unsigned_16;
      M2_Position : A0B.Types.Unsigned_16;
      M2_Current  : A0B.Types.Unsigned_16;
      M3_Position : A0B.Types.Unsigned_16;
      M3_Current  : A0B.Types.Unsigned_16;
   end record;

   Data      : array (1 .. 2_400) of Sensors_Data with Export;
   ADC1_Last : Natural := 0;
   ADC2_Last : Natural := 0;
   --  Buffer to accumulate data.

   --  Current : Sensors_Data;
   Average_Position : A0B.Types.Unsigned_16;

   procedure On_ADC1_DMA;

   procedure On_ADC2_DMA;

   package On_ADC1_DMA_Callbacks is
      new A0B.Callbacks.Generic_Parameterless (On_ADC1_DMA);

   package On_ADC2_DMA_Callbacks is
      new A0B.Callbacks.Generic_Parameterless (On_ADC2_DMA);

   ------------------
   -- Collect_Data --
   ------------------

   procedure Collect_Data is
   begin
      ADC1_Last := 0;
      ADC2_Last := 0;
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
      Configuration.ADC1_DMA_CH.DMA_CH.Set_Memory
        (Memory_Address  => ADC1_Buffer'Address,
         Number_Of_Items => ADC1_Buffer'Length * ADC1_Channels);
      Configuration.ADC1_DMA_CH.DMA_CH.Set_Interrupt_Callback
        (On_ADC1_DMA_Callbacks.Create_Callback);
      Configuration.ADC1_DMA_CH.DMA_CH.Enable_Transfer_Completed_Interrupt;
      Configuration.ADC1_DMA_CH.DMA_CH.Enable_Half_Transfer_Interrupt;
      Configuration.ADC1_DMA_CH.DMA_CH.Enable;

      Configuration.ADC2_DMA_CH.DMA_CH.Set_Memory
        (Memory_Address  => ADC2_Buffer'Address,
         Number_Of_Items => ADC2_Buffer'Length * ADC2_Channels);
      Configuration.ADC2_DMA_CH.DMA_CH.Set_Interrupt_Callback
        (On_ADC2_DMA_Callbacks.Create_Callback);
      Configuration.ADC2_DMA_CH.DMA_CH.Enable_Transfer_Completed_Interrupt;
      Configuration.ADC2_DMA_CH.DMA_CH.Enable_Half_Transfer_Interrupt;
      Configuration.ADC2_DMA_CH.DMA_CH.Enable;
   end Initialize;

   -----------------
   -- On_ADC1_DMA --
   -----------------

   procedure On_ADC1_DMA is
   begin
      --  Configuration.ADC1_DMA_CH.DMA_CH.Disable;

      if Configuration.ADC1_DMA_CH.DMA_CH.Get_Masked_And_Clear_Half_Transfer
      then
         if ADC1_Last <= Data'Last - ADC1_Buffer'Length / 2 then
      --        F := Buffer'First;
      --        L := Buffer'Length / 2;

            for J in ADC1_Buffer'First
                       .. ADC1_Buffer'First + ADC1_Buffer'Length / 2 - 1
            loop
               ADC1_Last := @ + 1;
               Data (ADC1_Last).M1_Current  := ADC1_Buffer (J).M1_Current;
               Data (ADC1_Last).M1_Position := ADC1_Buffer (J).M1_Position;
               Data (ADC1_Last).M2_Position := ADC1_Buffer (J).M2_Position;
            end loop;

         else
            raise Program_Error;
         end if;

         --  Current := Buffer (Buffer'Length / 2);
      end if;

      if Configuration.ADC1_DMA_CH.DMA_CH
           .Get_Masked_And_Clear_Transfer_Completed
      then
         if ADC1_Last <= Data'Last - ADC1_Buffer'Length / 2 then
      --     F := Buffer'First;
      --     L := Buffer'Length / 2;

            for J in ADC1_Buffer'First + ADC1_Buffer'Length / 2
                       .. ADC1_Buffer'Last
            loop
               ADC1_Last := @ + 1;
               Data (ADC1_Last).M1_Current  := ADC1_Buffer (J).M1_Current;
               Data (ADC1_Last).M1_Position := ADC1_Buffer (J).M1_Position;
               Data (ADC1_Last).M2_Position := ADC1_Buffer (J).M2_Position;
            end loop;
      --        Data (Last + 1 .. Last + Buffer'Length / 2) :=
      --          Buffer (Buffer'First + Buffer'Length / 2 .. Buffer'Last);
      --        Last := @ + Buffer'Length / 2;

         else
            raise Program_Error;
         end if;
      --
      --     Current := Buffer (Buffer'Last);
      end if;

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
   end On_ADC1_DMA;

   -----------------
   -- On_ADC2_DMA --
   -----------------

   procedure On_ADC2_DMA is
   begin
      if Configuration.ADC2_DMA_CH.DMA_CH.Get_Masked_And_Clear_Half_Transfer
      then
         if ADC2_Last <= Data'Last - ADC2_Buffer'Length / 2 then
      --        F := Buffer'First;
      --        L := Buffer'Length / 2;

            for J in ADC2_Buffer'First
                       .. ADC2_Buffer'First + ADC2_Buffer'Length / 2 - 1
            loop
               ADC2_Last := @ + 1;
               Data (ADC2_Last).M2_Current  := ADC2_Buffer (J).M2_Current;
               Data (ADC2_Last).M3_Current  := ADC2_Buffer (J).M3_Current;
               Data (ADC2_Last).M3_Position := ADC2_Buffer (J).M3_Position;
            end loop;
      --        Data (Last + 1 .. Last + Buffer'Length / 2) :=
      --          Buffer (Buffer'First .. Buffer'Length / 2);
      --        Last := @ + Buffer'Length / 2;

         else
            raise Program_Error;
         end if;
      --
      --     Current := Buffer (Buffer'Length / 2);
      end if;

      if Configuration.ADC2_DMA_CH.DMA_CH
           .Get_Masked_And_Clear_Transfer_Completed
      then
      --     F := Buffer'First;
      --     L := Buffer'Length / 2;

         if ADC2_Last <= Data'Last - ADC2_Buffer'Length / 2 then
            for J in ADC2_Buffer'First + ADC2_Buffer'Length / 2
                       .. ADC2_Buffer'Last
            loop
               ADC2_Last := @ + 1;
               Data (ADC2_Last).M2_Current  := ADC2_Buffer (J).M2_Current;
               Data (ADC2_Last).M3_Current  := ADC2_Buffer (J).M3_Current;
               Data (ADC2_Last).M3_Position := ADC2_Buffer (J).M3_Position;
            end loop;
      --        Data (Last + 1 .. Last + Buffer'Length / 2) :=
      --          Buffer (Buffer'First + Buffer'Length / 2 .. Buffer'Last);
      --        Last := @ + Buffer'Length / 2;
         else
            raise Program_Error;
         end if;

      --     Current := Buffer (Buffer'Last);
      end if;
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
   end On_ADC2_DMA;

end Sensors;
