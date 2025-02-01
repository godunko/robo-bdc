--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.SVD.ADC;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.TIM;
with A0B.STM32F401.TIM_Lines;
with A0B.STM32F401.USART.Configuration_Utilities;
with A0B.Types;

package body Configuration
  with Preelaborate
is

   Divider  : constant := 2#00#;  --  00: tDTS = tCK_INT
   Prescale : constant := 1;
   Cycle    : constant := 3_360;
   --  1/1/3_360: PWM 25kHz CPU @84MHz (nominal for L298)

   procedure Initialize_GPIO;

   procedure Initialize_DMA;

   procedure Initialize_ADC1;

   procedure Initialize_TIM3;
   --  Configure TIM3. Timer is disabled. It generates TRGO on CEN set.

   procedure Initialize_TIM4;
   --  Configure TIM4. Timer is disabled. It is configured to be triggered by
   --  set of CEN of TIM3.

   procedure Initialize_UART;

   procedure Enable_Timers;
   --  Enable all timers.

   -------------------
   -- Enable_Timers --
   -------------------

   procedure Enable_Timers is
   begin
      A0B.STM32F401.SVD.TIM.TIM3_Periph.CR1.CEN := True;
      --  Timers are configured in master-slave mode, so enable of TIM3 will
      --  enable other timers too.
   end Enable_Timers;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Initialize_GPIO;
      Initialize_DMA;
      Initialize_UART;
      Initialize_ADC1;
      Initialize_TIM3;
      Initialize_TIM4;

      Enable_Timers;
   end Initialize;

   ---------------------
   -- Initialize_ADC1 --
   ---------------------

   procedure Initialize_ADC1 is
      use A0B.STM32F401.SVD.ADC;

   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.ADC1EN := True;

      --  Clear SR - Not needed

      --  Configure CR1

      declare
         Aux : A0B.STM32F401.SVD.ADC.CR1_Register := ADC1_Periph.CR1;

      begin
         --  Aux.AWDCH := <>;  --  Not used
         Aux.EOCIE   := False;  --  0: EOC interrupt disabled
         Aux.AWDIE   := False;  --  0: Analog watchdog interrupt disabled
         Aux.JEOCIE  := False;  --  0: JEOC interrupt disabled
         Aux.SCAN    := True;   --  1: Scan mode enabled
         --  Aux.AWDSGL := <>;  --  Not used
         Aux.JAUTO   := False;
         --  0: Automatic injected group conversion disabled
         Aux.DISCEN  := False;
         --  0: Discontinuous mode on regular channels disabled
         Aux.JDISCEN := False;
         --  0: Discontinuous mode on injected channels disabled
         --  Aux.DISCNUM := <>;  --  Not used
         Aux.JAWDEN  := False;
         --  0: Analog watchdog disabled on injected channels
         Aux.AWDIE   := False;
         --  0: Analog watchdog disabled on regular channels
         Aux.RES     := 2#00#;  --  00: 12-bit (15 ADCCLK cycles)
         Aux.OVRIE   := False;  --  0: Overrun interrupt disabled

         ADC1_Periph.CR1 := Aux;
      end;

      --  Configure CR2

      declare
         Aux : A0B.STM32F401.SVD.ADC.CR2_Register := ADC1_Periph.CR2;

      begin
         Aux.ADON     := False;
         --  0: Disable ADC conversion and go to power down mode
         Aux.CONT     := True;    --  1: Continuous conversion mode
         --  XXX Aux.CONT     := False;    --  0: Single conversion mode
         Aux.DMA      := True;    --  1: DMA mode enabled
         Aux.DDS      := False;
         --  0: No new DMA request is issued after the last transfer (as
         --  configured in the DMA controller)
         --  XXX Aux.DDS      := True;
         --  XXX 1: DMA requests are issued as long as data are converted and
         --  DMA=1
         Aux.EOCS     := True;
         --  1: The EOC bit is set at the end of each regular conversion.
         --  Overrun detection is enabled.
         Aux.ALIGN    := False;    --  0: Right alignment
         --  Aux.JEXTSEL := <>;  --  Not used
         Aux.JEXTEN   := 2#00#;    --  00: Trigger detection disabled
         Aux.JSWSTART := False;    --  0: Reset state
         Aux.EXTSEL   := 2#1010#;  --  1010: Timer 5 CC1 event
         Aux.EXTEN    := 2#01#;    --  01: Trigger detection on the rising edge
         Aux.SWSTART  := False;    --  0: Reset state

         ADC1_Periph.CR2 := Aux;
      end;

      --  Configure SMPR1

      ADC1_Periph.SMPR1 := 0; --  000: 3 cycles, for channels 10..18

      --  Configure SMPR2

      ADC1_Periph.SMPR2 := 0; --  000: 3 cycles, for channels 0..9

      --  Configure JOFR1 - Not used

      --  Configure JOFR2 - Not used

      --  Configure JOFR3 - Not used

      --  Configure JOFR4 - Not used

      --  Configure HTR - Not used

      --  Configure LTR - Not used

      --  Configure SQR1

      declare
         Aux : A0B.STM32F401.SVD.ADC.SQR1_Register := ADC1_Periph.SQR1;

      begin
         --  Aux.SQ.Arr (16) := <>;  --  Not used
         --  Aux.SQ.Arr (15) := <>;  --  Not used
         --  Aux.SQ.Arr (14) := <>;  --  Not used
         --  Aux.SQ.Arr (13) := <>;  --  Not used
         Aux.L := 2#1000#;  --  1000: 9 conversions

         ADC1_Periph.SQR1 := Aux;
      end;

      --  Configure SQR2

      declare
         Aux : A0B.STM32F401.SVD.ADC.SQR2_Register := ADC1_Periph.SQR2;

      begin
         --  Aux.SQ.Arr (12) := <>;  --  Not used
         --  Aux.SQ.Arr (11) := <>;  --  Not used
         --  Aux.SQ.Arr (10) := <>;  --  Not used
         Aux.SQ.Arr (9) := 7;   --  IN7
         Aux.SQ.Arr (8) := 6;   --  IN6
         Aux.SQ.Arr (7) := 5;   --  IN5

         ADC1_Periph.SQR2 := Aux;
      end;

      --  Configure SQR3

      declare
         Aux : A0B.STM32F401.SVD.ADC.SQR3_Register := ADC1_Periph.SQR3;

      begin
         Aux.SQ.Arr (6) := 4;   --  IN4
         Aux.SQ.Arr (5) := 3;   --  IN3
         Aux.SQ.Arr (4) := 2;   --  IN2
         Aux.SQ.Arr (3) := 1;   --  IN1
         Aux.SQ.Arr (2) := 0;   --  IN0
         Aux.SQ.Arr (1) := 17;  --  IN17 VREFINT

         ADC1_Periph.SQR3 := Aux;
      end;

      --  Configure JSQR - Not used

      --  Configure CCR

      declare
         Aux : CCR_Register := ADC_Common_Periph.CCR;

      begin
         Aux.ADCPRE  := 2#01#;  --  PCLK2 divided by 4
         Aux.VBATE   := False;  --  0: VBAT channel disabled
         Aux.TSVREFE := True;
         --  1: Temperature sensor and VREFINT channel enabled

         ADC_Common_Periph.CCR := Aux;
      end;

      --  Enable ADC

      ADC1_Periph.CR2.ADON := True;
   end Initialize_ADC1;

   --------------------
   -- Initialize_DMA --
   --------------------

   procedure Initialize_DMA is
   begin
      ADC1_DMA_Stream.Configure_Peripheral_To_Memory
        (Channel              => 0,
         Peripheral           => A0B.STM32F401.SVD.ADC.ADC1_Periph.DR'Address,
         Peripheral_Data_Size => A0B.STM32F401.DMA.Half_Word,
         Memory_Data_Size     => A0B.STM32F401.DMA.Half_Word);
   end Initialize_DMA;

   ---------------------
   -- Initialize_GPIO --
   ---------------------

   procedure Initialize_GPIO is
   begin
      --  ADC1 input

      M1_C_Pin.Configure_Analog;
      M1_P_Pin.Configure_Analog;
      M2_C_Pin.Configure_Analog;
      M2_P_Pin.Configure_Analog;
      M3_C_Pin.Configure_Analog;
      M3_P_Pin.Configure_Analog;
      M4_C_Pin.Configure_Analog;
      M4_P_Pin.Configure_Analog;

      --  TIM3 output

      M1_IN1_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM3_CH1,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      M1_IN2_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM3_CH2,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      M2_IN1_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM3_CH3,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      M2_IN2_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM3_CH4,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);

      --  TIM4 output

      M3_IN1_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM4_CH1,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      M3_IN2_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM4_CH2,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      M4_IN1_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM4_CH3,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      M4_IN2_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM4_CH4,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);

      --  USART's input/output pins are configured by the USART driver
   end Initialize_GPIO;

   ---------------------
   -- Initialize_TIM3 --
   ---------------------

   procedure Initialize_TIM3 is
      use A0B.STM32F401.SVD.TIM;
      use type A0B.Types.Unsigned_16;

      TIM : TIM3_Peripheral renames TIM3_Periph;

   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB1ENR.TIM3EN := True;

      --  Configure CR1

      declare
         Aux : A0B.STM32F401.SVD.TIM.CR1_Register := TIM.CR1;

      begin
         Aux.CEN  := False;  --  0: Counter disabled
         Aux.UDIS := False;  --  0: UEV enabled
         Aux.URS  := False;
         --  0: Any of the following events generate an update interrupt or DMA
         --  request if enabled.
         --
         --  These events can be:
         --  – Counter overflow/underflow
         --  – Setting the UG bit
         --  – Update generation through the slave mode controller
         Aux.OPM  := False;  --  0: Counter is not stopped at update event
         Aux.DIR  := False;  --  0: Counter used as upcounter
         Aux.CMS  := 2#00#;
         --  00: Edge-aligned mode. The counter counts up or down depending on
         --  the direction bit (DIR).
         Aux.ARPE := True;   --  1: TIMx_ARR register is buffered
         Aux.CKD  := Divider;

         TIM.CR1 := Aux;
      end;

      --  Configure CR2

      declare
         Aux : CR2_Register_1 := TIM.CR2;

      begin
         --  Aux.CCDS := <>;  --  Not needed
         Aux.MMS  := 2#001#;
         --  001: Enable - the Counter enable signal, CNT_EN, is used as
         --  trigger output (TRGO). It is useful to start several timers at
         --  the same time or to control a window in which a slave timer is
         --  enabled. The Counter Enable signal is generated by a logic OR
         --  between CEN control bit and the trigger input when configured
         --  in gated mode.
         --
         --  When the Counter Enable signal is controlled by the trigger input,
         --  there is a delay on TRGO, except if the master/slave mode is
         --  selected (see the MSM bit description in TIMx_SMCR register).
         Aux.TI1S := False;  --  0: The TIMx_CH1 pin is connected to TI1 input

         TIM.CR2 := Aux;
      end;

      --  Configure SMCR

      declare
         Aux : SMCR_Register := TIM.SMCR;

      begin
         Aux.SMS  := 2#000#;
         --  000: Slave mode disabled - if CEN = ‘1 then the prescaler is
         --  clocked directly by the internal clock.
         --  Aux.TS   := <>;  --  Not used
         Aux.MSM  := True;
         --  1: The effect of an event on the trigger input (TRGI) is delayed
         --  to allow a perfect synchronization between the current timer and
         --  its slaves (through TRGO). It is useful if we want to synchronize
         --  several timers on a single external event.
         --  Aux.ETF  := <>;  --  Not used
         --  Aux.ETPS := <>;  --  Not used
         --  Aux.ECE  := <>;  --  Not used
         --  Aux.ETP  := <>;  --  Not used

         TIM.SMCR := Aux;
      end;

      --  Configure DIER - Not used

      --  XXX Reset SR by write 0?

      --  Set EGR - Not used

      --  Configure CCMR1

      declare
         Aux : CCMR1_Output_Register := TIM.CCMR1_Output;

      begin
         Aux.CC1S  := 2#00#;  --  00: CC1 channel is configured as output.
         Aux.OC1FE := False;
         --  0: CC1 behaves normally depending on counter and CCR1 values even
         --  when the trigger is ON. The minimum delay to activate CC1 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC1PE := True;
         --  1: Preload register on TIMx_CCR1 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR1 preload value is loaded
         --  in the active register at each update event.
         Aux.OC1M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR1 else inactive. In downcounting, channel 1 is
         --  inactive (OC1REF=‘0) as long as TIMx_CNT>TIMx_CCR1 else active
         --  (OC1REF=1).
         Aux.OC1CE := False;  --  0: OC1Ref is not affected by the ETRF input
         Aux.CC2S  := 2#00#;  --  00: CC2 channel is configured as output
         Aux.OC2FE := False;
         --  0: CC2 behaves normally depending on counter and CCR2 values even
         --  when the trigger is ON. The minimum delay to activate CC2 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC2PE := True;
         --  1: Preload register on TIMx_CCR2 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR2 preload value is loaded
         --  in the active register at each update event.
         Aux.OC2M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 2 is active as long as
         --  TIMx_CNT<TIMx_CCR2 else inactive. In downcounting, channel 2 is
         --  inactive (OC2REF=‘0) as long as TIMx_CNT>TIMx_CCR2 else active
         --  (OC2REF=1).
         Aux.OC2CE := False; --  0: OC2Ref is not affected by the ETRF input

         TIM.CCMR1_Output := Aux;
      end;

      --  Configure CCMR2

      declare
         Aux : CCMR2_Output_Register := TIM.CCMR2_Output;

      begin
         Aux.CC3S  := 2#00#;  --  00: CC3 channel is configured as output.
         Aux.OC3FE := False;
         --  0: CC3 behaves normally depending on counter and CCR2 values even
         --  when the trigger is ON. The minimum delay to activate CC3 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC3PE := True;
         --  1: Preload register on TIMx_CCR3 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR3 preload value is loaded
         --  in the active register at each update event.
         Aux.OC3M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 3 is active as long as
         --  TIMx_CNT<TIMx_CCR3 else inactive. In downcounting, channel 1 is
         --  inactive (OC3REF=‘0) as long as TIMx_CNT>TIMx_CCR3 else active
         --  (OC3REF=1).
         Aux.OC3CE := False;  --  0: OC3Ref is not affected by the ETRF input
         Aux.CC4S  := 2#00#;  --  00: CC4 channel is configured as output
         Aux.OC4FE := False;
         --  0: CC4 behaves normally depending on counter and CCR4 values even
         --  when the trigger is ON. The minimum delay to activate CC4 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC4PE := True;
         --  1: Preload register on TIMx_CCR4 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR4 preload value is loaded
         --  in the active register at each update event.
         Aux.OC4M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 4 is active as long as
         --  TIMx_CNT<TIMx_CCR4 else inactive. In downcounting, channel 4 is
         --  inactive (OC4REF=‘0) as long as TIMx_CNT>TIMx_CCR4 else active
         --  (OC4REF=1).
         Aux.OC4CE := False; --  0: OC4Ref is not affected by the ETRF input

         TIM.CCMR2_Output := Aux;
      end;

      --  Configure CCER

      declare
         Aux : CCER_Register_1 := TIM.CCER;

      begin
         Aux.CC1E  := True;
         --  1: On - OC1 signal is output on the corresponding output pin
         Aux.CC1P  := False;  --  0: OC1 active high
         Aux.CC1NP := False;
         --  CC1 channel configured as output: CC1NP must be kept cleared in
         --  this case.
         Aux.CC2E  := True;
         --  1: On - OC2 signal is output on the corresponding output pin
         Aux.CC2P  := False;  --  0: OC2 active high
         Aux.CC2NP := False;
         --  CC2 channel configured as output: CC2NP must be kept cleared in
         --  this case.
         Aux.CC3E  := True;
         --  1: On - OC3 signal is output on the corresponding output pin
         Aux.CC3P  := False;  --  0: OC3 active high
         Aux.CC3NP := False;
         --  CC3 channel configured as output: CC3NP must be kept cleared in
         --  this case.
         Aux.CC4E  := True;
         --  1: On - OC4 signal is output on the corresponding output pin
         Aux.CC4P  := False;  --  0: OC4 active high
         Aux.CC4NP := False;
         --  CC4 channel configured as output: CC4NP must be kept cleared in
         --  this case.

         TIM.CCER := Aux;
      end;

      --  Set CNT to zero (TIM3/TIM4 support low part only)

      TIM.CNT.CNT_L := 0;

      --  Set PSC

      TIM.PSC.PSC := Prescale;

      --  Set ARR (TIM3/TIM4 support low part only)

      TIM.ARR.ARR_L := Cycle - 1;

      --  Set CCR1/CCR2/CCR3/CCR4 later

      --  Configure DCR - Not used

      --  Configure DMAR - Not used

      --  Force update event to load configured values of ARR/PSC to shadow
      --  registers.

      TIM.EGR.UG := True;
   end Initialize_TIM3;

   ---------------------
   -- Initialize_TIM4 --
   ---------------------

   procedure Initialize_TIM4 is
      use A0B.STM32F401.SVD.TIM;
      use type A0B.Types.Unsigned_16;

      TIM : TIM3_Peripheral renames TIM4_Periph;

   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB1ENR.TIM4EN := True;

      --  Configure CR1

      declare
         Aux : A0B.STM32F401.SVD.TIM.CR1_Register := TIM.CR1;

      begin
         Aux.CEN  := False;  --  0: Counter disabled
         Aux.UDIS := False;  --  0: UEV enabled
         Aux.URS  := False;
         --  0: Any of the following events generate an update interrupt or DMA
         --  request if enabled.
         --
         --  These events can be:
         --  – Counter overflow/underflow
         --  – Setting the UG bit
         --  – Update generation through the slave mode controller
         Aux.OPM  := False;  --  0: Counter is not stopped at update event
         Aux.DIR  := False;  --  0: Counter used as upcounter
         Aux.CMS  := 2#00#;
         --  00: Edge-aligned mode. The counter counts up or down depending on
         --  the direction bit (DIR).
         Aux.ARPE := True;   --  1: TIMx_ARR register is buffered
         Aux.CKD  := Divider;

         TIM.CR1 := Aux;
      end;

      --  Configure CR2

      declare
         Aux : CR2_Register_1 := TIM.CR2;

      begin
         --  Aux.CCDS := <>;  --  Not needed
         --  Aux.MMS  := <>;  --  Not needed
         Aux.TI1S := False;  --  0: The TIMx_CH1 pin is connected to TI1 input

         TIM.CR2 := Aux;
      end;

      --  Configure SMCR

      declare
         Aux : SMCR_Register := TIM.SMCR;

      begin
         Aux.SMS  := 2#110#;
         --  110: Trigger Mode - The counter starts at a rising edge of the
         --  trigger TRGI (but it is not reset). Only the start of the counter
         --  is controlled.
         Aux.TS   := 2#010#;  --  010: Internal Trigger 2 (ITR2).
         Aux.MSM  := True;
         --  1: The effect of an event on the trigger input (TRGI) is delayed
         --  to allow a perfect synchronization between the current timer and
         --  its slaves (through TRGO). It is useful if we want to synchronize
         --  several timers on a single external event.
         --  Aux.ETF  := <>;  --  Not used
         --  Aux.ETPS := <>;  --  Not used
         --  Aux.ECE  := <>;  --  Not used
         --  Aux.ETP  := <>;  --  Not used

         TIM.SMCR := Aux;
      end;

      --  Configure DIER - Not used

      --  XXX Reset SR by write 0?

      --  Set EGR - Not used

      --  Configure CCMR1

      declare
         Aux : CCMR1_Output_Register := TIM.CCMR1_Output;

      begin
         Aux.CC1S  := 2#00#;  --  00: CC1 channel is configured as output.
         Aux.OC1FE := False;
         --  0: CC1 behaves normally depending on counter and CCR1 values even
         --  when the trigger is ON. The minimum delay to activate CC1 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC1PE := True;
         --  1: Preload register on TIMx_CCR1 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR1 preload value is loaded
         --  in the active register at each update event.
         Aux.OC1M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR1 else inactive. In downcounting, channel 1 is
         --  inactive (OC1REF=‘0) as long as TIMx_CNT>TIMx_CCR1 else active
         --  (OC1REF=1).
         Aux.OC1CE := False;  --  0: OC1Ref is not affected by the ETRF input
         Aux.CC2S  := 2#00#;  --  00: CC2 channel is configured as output
         Aux.OC2FE := False;
         --  0: CC2 behaves normally depending on counter and CCR2 values even
         --  when the trigger is ON. The minimum delay to activate CC2 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC2PE := True;
         --  1: Preload register on TIMx_CCR2 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR2 preload value is loaded
         --  in the active register at each update event.
         Aux.OC2M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 2 is active as long as
         --  TIMx_CNT<TIMx_CCR2 else inactive. In downcounting, channel 2 is
         --  inactive (OC2REF=‘0) as long as TIMx_CNT>TIMx_CCR2 else active
         --  (OC2REF=1).
         Aux.OC2CE := False; --  0: OC2Ref is not affected by the ETRF input

         TIM.CCMR1_Output := Aux;
      end;

      --  Configure CCMR2

      declare
         Aux : CCMR2_Output_Register := TIM.CCMR2_Output;

      begin
         Aux.CC3S  := 2#00#;  --  00: CC3 channel is configured as output.
         Aux.OC3FE := False;
         --  0: CC3 behaves normally depending on counter and CCR2 values even
         --  when the trigger is ON. The minimum delay to activate CC3 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC3PE := True;
         --  1: Preload register on TIMx_CCR3 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR3 preload value is loaded
         --  in the active register at each update event.
         Aux.OC3M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 3 is active as long as
         --  TIMx_CNT<TIMx_CCR3 else inactive. In downcounting, channel 1 is
         --  inactive (OC3REF=‘0) as long as TIMx_CNT>TIMx_CCR3 else active
         --  (OC3REF=1).
         Aux.OC3CE := False;  --  0: OC3Ref is not affected by the ETRF input
         Aux.CC4S  := 2#00#;  --  00: CC4 channel is configured as output
         Aux.OC4FE := False;
         --  0: CC4 behaves normally depending on counter and CCR4 values even
         --  when the trigger is ON. The minimum delay to activate CC4 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Aux.OC4PE := True;
         --  1: Preload register on TIMx_CCR4 enabled. Read/Write operations
         --  access the preload register. TIMx_CCR4 preload value is loaded
         --  in the active register at each update event.
         Aux.OC4M  := 2#110#;
         --  110: PWM mode 1 - In upcounting, channel 4 is active as long as
         --  TIMx_CNT<TIMx_CCR4 else inactive. In downcounting, channel 4 is
         --  inactive (OC4REF=‘0) as long as TIMx_CNT>TIMx_CCR4 else active
         --  (OC4REF=1).
         Aux.OC4CE := False; --  0: OC4Ref is not affected by the ETRF input

         TIM.CCMR2_Output := Aux;
      end;

      --  Configure CCER

      declare
         Aux : CCER_Register_1 := TIM.CCER;

      begin
         Aux.CC1E  := True;
         --  1: On - OC1 signal is output on the corresponding output pin
         Aux.CC1P  := False;  --  0: OC1 active high
         Aux.CC1NP := False;
         --  CC1 channel configured as output: CC1NP must be kept cleared in
         --  this case.
         Aux.CC2E  := True;
         --  1: On - OC2 signal is output on the corresponding output pin
         Aux.CC2P  := False;  --  0: OC2 active high
         Aux.CC2NP := False;
         --  CC2 channel configured as output: CC2NP must be kept cleared in
         --  this case.
         Aux.CC3E  := True;
         --  1: On - OC3 signal is output on the corresponding output pin
         Aux.CC3P  := False;  --  0: OC3 active high
         Aux.CC3NP := False;
         --  CC3 channel configured as output: CC3NP must be kept cleared in
         --  this case.
         Aux.CC4E  := True;
         --  1: On - OC4 signal is output on the corresponding output pin
         Aux.CC4P  := False;  --  0: OC4 active high
         Aux.CC4NP := False;
         --  CC4 channel configured as output: CC4NP must be kept cleared in
         --  this case.

         TIM.CCER := Aux;
      end;

      --  Set CNT to zero (TIM3/TIM4 support low part only)

      TIM.CNT.CNT_L := 0;

      --  Set PSC

      TIM.PSC.PSC := Prescale;

      --  Set ARR (TIM3/TIM4 support low part only)

      TIM.ARR.ARR_L := Cycle - 1;

      --  Set CCR1/CCR2/CCR3/CCR4 later

      --  Configure DCR - Not used

      --  Configure DMAR - Not used

      --  Force update event to load configured values of ARR/PSC to shadow
      --  registers.

      TIM.EGR.UG := True;
   end Initialize_TIM4;

   ---------------------
   -- Initialize_UART --
   ---------------------

   procedure Initialize_UART is
      Configuration : A0B.STM32F401.USART.Asynchronous_Configuration;

   begin
      A0B.STM32F401.USART.Configuration_Utilities.Compute_Configuration
        (Peripheral_Frequency => 84_000_000,
         Baud_Rate            => 115_200,
         Configuration        => Configuration);

      UART1.USART1_Asynchronous.Configure (Configuration);
   end Initialize_UART;

end Configuration;
