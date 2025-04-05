--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Asynchronous_Operations;
with A0B.Awaits;

with Configuration;

package body Console is

   ---------
   -- Get --
   ---------

   procedure Get (Item : out Character) is
      Buffer  : A0B.Asynchronous_Operations.Transfer_Descriptor :=
        (Buffer      => Item'Address,
         Length      => 1,
         Transferred => <>,
         State       => <>);
      Await   : aliased A0B.Awaits.Await;
      Success : Boolean := True;

   begin
      Configuration.Console_UART.Receive
        (Buffer   => Buffer,
         Finished => A0B.Awaits.Create_Callback (Await),
         Success  => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Get;

   --------------
   -- New_Line --
   --------------

   procedure New_Line is
   begin
      Put (ASCII.CR & ASCII.LF);
   end New_Line;

   ---------
   -- Put --
   ---------

   procedure Put (Item : Character) is
      Buffer : String (1 .. 1);

   begin
      Buffer (Buffer'First) := Item;
      Put (Buffer);
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (Item : String) is
      Buffer  : A0B.Asynchronous_Operations.Transfer_Descriptor :=
        (Buffer      => Item (Item'First)'Address,
         Length      => Item'Length,
         Transferred => <>,
         State       => <>);
      Await   : aliased A0B.Awaits.Await;
      Success : Boolean := True;

   begin
      Configuration.Console_UART.Transmit
        (Buffer   => Buffer,
         Finished => A0B.Awaits.Create_Callback (Await),
         Success  => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Item : String) is
   begin
      Put (Item);
      New_Line;
   end Put_Line;

end Console;
