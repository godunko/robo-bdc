--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.NVIC_Utilities;
with A0B.ARMv7M.SysTick_Clock_Timer;
with A0B.STM32.TIM_Lines;
with A0B.STM32G474.Interrupts;
with A0B.STM32G474.SVD.ADC;
with A0B.STM32G474.SVD.OPAMP;
with A0B.STM32G474.SVD.RCC;
with A0B.STM32G474.SVD.TIM;
with A0B.Types;

package body Configuration
  with Preelaborate
is

   use type A0B.Types.Unsigned_16;

   CPU_Frequency         : constant := 150_000_000;
   ADC_PWM_TIM_Prescaler : constant := 4;
   --  Same value as ADC prescaler to workaround ADC errata
   PWM_TIM_Cycles        : constant := 1500;
   ADC_TIM_Cycles        : constant := 125;

   --  ADC12_IN1   : constant := 1;
   ADC12_IN2   : constant := 2;
   --  ADC1_IN3    : constant := 3;
   --  ADC2_IN3    : constant := 3;
   --  ADC1_IN4    : constant := 4;
   ADC2_IN4    : constant := 4;
   --  ADC1_IN5    : constant := 5;
   --  ADC2_IN5    : constant := 5;
   --  ADC12_IN6   : constant := 6;
   --  ADC12_IN7   : constant := 7;
   --  ADC12_IN8   : constant := 8;
   --  ADC12_IN9   : constant := 9;
   --  ADC1_IN10   : constant := 10;
   --  ADC2_IN10   : constant := 10;
   --  ADC1_IN11   : constant := 11;
   --  ADC2_IN11   : constant := 11;
   ADC1_IN12   : constant := 12;
   --  ADC2_IN12   : constant := 12;
   ADC1_OPAMP1  : constant := 13;
   --  ADC2_IN13   : constant := 13;
   --  ADC12_IN14  : constant := 14;
   ADC1_IN15   : constant := 15;
   --  ADC2_IN15   : constant := 15;
   --  ADC1_VTS     : constant := 16;
   --  ADC2_OPAMP2  : constant := 16;
   --  ADC1_VBAT_3  : constant := 17;
   ADC2_IN17   : constant := 17;
   --  ADC1_VREFINT : constant := 18;
   --  ADC2_OPAMP3  : constant := 18;

   procedure USART1_Handler
     with Export, Convention => C, External_Name => "USART1_Handler";

   --  Divider   : constant := 2#00#;  --  00: tDTS = tCK_INT
   --  Prescale  : constant := 1;
   --  PWM_Cycle : constant := 3_360;
   --  --  1/1/3_360: PWM 25kHz CPU @84MHz (nominal for L298)
   --  ADC_Cycle : constant := 560;
   --  --  1/1/560: 6x ADC samples per PWM cycle

   procedure Initialize_GPIO;

   procedure Initialize_OPAMP;

   procedure Initialize_DMA;

   procedure Initialize_ADC;
   --  Initialize ADC1 and ADC2

   procedure Initialize_TIM2;
   --  Configure TIM2 to generate PWM. Timer is disabled. It generates TRGO on
   --  CEN set.

   procedure Initialize_TIM3;
   --  Configure TIM3 to generate PWM. Timer is disabled. It is configured to
   --  be triggered by set of CEN of TIM2.

   procedure Initialize_TIM4;
   --  Configure TIM4 to generate PWM. Timer is disabled. It is configured to
   --  be triggered by set of CEN of TIM2.

   procedure Initialize_TIM15;
   --  Configure TIM15 to initiate ADC sampling. It is configured to
   --  be triggered by set of CEN of TIM2.

   procedure Initialize_Console_UART;

   -------------------
   -- Enable_Timers --
   -------------------

   procedure Enable_Timers is
   begin
      A0B.STM32G474.SVD.TIM.TIM2_Periph.CR1.CEN := True;
      --  Timers are configured in master-slave mode, so enable of TIM3 will
      --  enable other timers too.
   end Enable_Timers;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.ARMv7M.SysTick_Clock_Timer.Initialize
        (Use_Processor_Clock => True,
         Clock_Frequency     => CPU_Frequency);

      Initialize_GPIO;
      Initialize_OPAMP;
      Initialize_DMA;
      Initialize_Console_UART;
      Initialize_ADC;
      Initialize_TIM2;
      Initialize_TIM3;
      Initialize_TIM4;
      Initialize_TIM15;
   end Initialize;

   --------------------
   -- Initialize_ADC --
   --------------------

   procedure Initialize_ADC is

      procedure Initialize_ADC1;

      procedure Initialize_ADC2;

      procedure Initialize_ADCx
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral);
      --  Shared initialization code of both ADC

      procedure Initialize_ADC12_Clock;
      --  ADC12 clock

      procedure Initialize_ADC12_Common;
      --  ADC1/ADC2 Common peripheral

      procedure Start_ADC_Operations
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral);
      --  Left Deep-power-down mode and activate voltage regulator

      procedure Calibrate_Single_Ended
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral);
      --  Perform ADC calibration procedure.

      procedure Enable_ADC
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral);

      procedure Start_ADC (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral);
      --  Starts ADC conversions.

      ----------------------------
      -- Calibrate_Single_Ended --
      ----------------------------

      procedure Calibrate_Single_Ended
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral) is
      begin
         ADC.CR :=
           (ADCALDIF => False,
            ADCAL    => True,
            DEEPPWD  => False,
            ADVREGEN => True,
            others => <>);

         while ADC.CR.ADCAL loop
            null;
         end loop;
      end Calibrate_Single_Ended;

      ----------------
      -- Enable_ADC --
      ----------------

      procedure Enable_ADC
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral) is
      begin
         ADC.ISR := (ADRDY => True, others => <>);
         --  1. Clear the ADRDY bit in the ADC_ISR register by writing 1.

         ADC.CR :=
           (ADEN => True, ADVREGEN => True, DEEPPWD => False, others => <>);
         --  2. Set ADEN.

         while not ADC.ISR.ADRDY loop
            --  3. Wait until ADRDY = 1 (ADRDY is set after the ADC startup
            --  time). This can be done using the associated interrupt (setting
            --  ADRDYIE = 1).

            null;
         end loop;

         ADC.ISR := (ADRDY => True, others => <>);
         --  4. Clear the ADRDY bit in the ADC_ISR register by writing 1
         --  (optional).
      end Enable_ADC;

      ---------------------
      -- Initialize_ADC1 --
      ---------------------

      procedure Initialize_ADC1 is
         ADC : A0B.STM32G474.SVD.ADC.ADC1_Peripheral
           renames A0B.STM32G474.SVD.ADC.ADC1_Periph;

      begin
         Initialize_ADCx (ADC);

         --  ADC regular sequence register 1 (ADC_SQR1)

         declare
            Value : A0B.STM32G474.SVD.ADC.SQR1_Register := ADC.SQR1;

         begin
            Value.L   := 5;  --  6 conversions
            Value.SQ1 := ADC1_IN12;
            Value.SQ2 := ADC1_IN12;
            Value.SQ3 := ADC1_IN15;
            Value.SQ4 := ADC1_IN15;

            ADC.SQR1 := Value;
         end;

         --  ADC regular sequence register 2 (ADC_SQR2)

         declare
            Value : A0B.STM32G474.SVD.ADC.SQR2_Register := ADC.SQR2;

         begin
            --  Value.SQ5 := ADC1_IN4;
            --  Value.SQ6 := ADC1_IN4;
            Value.SQ5 := ADC1_OPAMP1;
            Value.SQ6 := ADC1_OPAMP1;

            ADC.SQR2 := Value;
         end;
      end Initialize_ADC1;

      ---------------------
      -- Initialize_ADC2 --
      ---------------------

      procedure Initialize_ADC2 is
         ADC : A0B.STM32G474.SVD.ADC.ADC1_Peripheral
           renames A0B.STM32G474.SVD.ADC.ADC2_Periph;

      begin
         Initialize_ADCx (ADC);

         --  ADC regular sequence register 1 (ADC_SQR1)

         declare
            Value : A0B.STM32G474.SVD.ADC.SQR1_Register := ADC.SQR1;

         begin
            --  Value.L   := 2#0010#;  --  3 conversions
            Value.L   := 5;  --  6 conversions
            Value.SQ1 := ADC2_IN17;
            Value.SQ2 := ADC2_IN17;
            Value.SQ3 := ADC2_IN4;
            Value.SQ4 := ADC2_IN4;
            --  Value.SQ3 := ADC2_OPAMP2;
            --  Value.SQ4 := ADC2_OPAMP2;

            ADC.SQR1 := Value;
         end;

         --  ADC regular sequence register 2 (ADC_SQR2)

         declare
            Value : A0B.STM32G474.SVD.ADC.SQR2_Register := ADC.SQR2;

         begin
            Value.SQ5 := ADC12_IN2;
            Value.SQ6 := ADC12_IN2;
            --  Value.SQ5 := ADC2_OPAMP3;
            --  Value.SQ6 := ADC2_OPAMP3;

            ADC.SQR2 := Value;
         end;
      end Initialize_ADC2;

      ---------------------
      -- Initialize_ADCx --
      ---------------------

      procedure Initialize_ADCx
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral) is
      begin
         --  ADC interrupt enable register (ADC_IER)

         declare
            Value : A0B.STM32G474.SVD.ADC.IER_Register := ADC.IER;

         begin
            Value.ADRDYIE := False;  --  0: ADRDY interrupt disabled
            Value.EOSMPIE := False;  --  0: EOSMP interrupt disabled
            Value.EOCIE   := False;  --  0: EOC interrupt disabled
            Value.EOSIE   := False;  --  0: EOS interrupt disabled
            Value.OVRIE   := False;  --  0: Overrun interrupt disabled
            Value.JEOCIE  := False;  --  0: JEOC interrupt disabled
            Value.JEOSIE  := False;  --  0: JEOS interrupt disabled
            Value.AWD1IE  := False;
            --  0: Analog watchdog 1 interrupt disabled
            Value.AWD2IE  := False;
            --  0: Analog watchdog 1 interrupt disabled
            Value.AWD3IE  := False;
            --  0: Analog watchdog 3 interrupt disabled
            Value.JQOVFIE := False;
            --  0: Injected Context Queue Overflow interrupt disabled

            ADC.IER := Value;
         end;

         --  ADC control register (ADC_CR)

         --  ADC configuration register (ADC_CFGR)

         declare
            Value : A0B.STM32G474.SVD.ADC.CFGR_Register := ADC.CFGR;

         begin
            Value.DMAEN   := True;      --  1: DMA enabled
            Value.DMACFG  := True;      --  1: DMA Circular mode selected
            Value.RES     := 2#00#;     --  00: 12-bit
            Value.EXTSEL  := 2#01110#;  --  adc_ext_trg14: tim15_trgo
            Value.EXTEN   := 2#01#;
            --  01: Hardware trigger detection on the rising edge
            --  --  00: Hardware trigger detection disabled (conversions can be
            --  --  launched by software)
            Value.OVRMOD  := False;
            --  0: ADC_DR register is preserved with the old data when an
            --  overrun is detected.
            Value.CONT    := False;     --  0: Single conversion mode
            Value.AUTDLY  := False;     --  0: Auto-delayed conversion mode off
            Value.ALIGN   := False;     --  0: Right alignment
            Value.DISCEN  := False;
            --  0: Discontinuous mode for regular channels disabled
            Value.DISCNUM := 0;         --  <>
            Value.JDISCEN := False;
            --  0: Discontinuous mode on injected channels disabled
            Value.JQM     := False;
            --  0: JSQR mode 0: The Queue is never empty and maintains the last
            --  written configuration into JSQR
            Value.AWD1SGL := False;
            --  0: Analog watchdog 1 enabled on all channels
            Value.AWD1EN  := False;
            --  0: Analog watchdog 1 disabled on regular channels
            Value.JAWD1EN := False;
            --  0: Analog watchdog 1 disabled on injected channels
            Value.JAUTO   := False;
            --  0: Automatic injected group conversion disabled
            Value.AWD1CH  := 2#00000#;  --  <>
            Value.JQDIS   := True;      --  1: Injected Queue disabled

            ADC.CFGR := Value;
         end;

         --  ADC configuration register 2 (ADC_CFGR2)

         declare
            Value : A0B.STM32G474.SVD.ADC.CFGR2_Register := ADC.CFGR2;

         begin
            Value.ROVSE   := False;    --  0: Regular Oversampling disabled
            Value.JOVSE   := False;    --  0: Injected Oversampling disabled
            Value.OVSR    := 2#000#;   --  <>
            Value.OVSS    := 2#0000#;  --  <>
            Value.TROVS   := False;
            --  0: All oversampled conversions for a channel are done
            --  consecutively following a trigger
            Value.ROVSM   := False;
            --  0: Continued mode: When injected conversions are triggered,
            --  the oversampling is temporary stopped and continued after the
            --  injection sequence (oversampling buffer is maintained during
            --  injected sequence)
            Value.GCOMP   := False;    --  0: Regular ADC operating mode
            Value.SWTRIG  := False;
            --  0: Software trigger starts the conversion for sampling time
            --  control trigger mode
            Value.BULB    := False;    --  0: Bulb sampling mode disabled
            Value.SMPTRIG := False;
            --  0: Sampling time control trigger mode disabled

            ADC.CFGR2 := Value;
         end;

         --  ADC sample time register 1 (ADC_SMPR1)

         declare
            Value : A0B.STM32G474.SVD.ADC.SMPR1_Register := ADC.SMPR1;

         begin
            Value.SMPPLUS := False;
            --  0: The sampling time remains set to 2.5 ADC clock cycles
            --  remains
            Value.SMP.Arr := (others => 2#001#);  --  000: 6.5 ADC clock cycles

            ADC.SMPR1 := Value;
         end;

         --  ADC sample time register 2 (ADC_SMPR2)

         declare
            Value : A0B.STM32G474.SVD.ADC.SMPR2_Register := ADC.SMPR2;

         begin
            Value.SMP.Arr := (others => 2#001#);  --  000: 6.5 ADC clock cycles

            ADC.SMPR2 := Value;
         end;

         --  ADC watchdog threshold register 1 (ADC_TR1)
         --  ADC watchdog threshold register 2 (ADC_TR2)
         --  ADC watchdog threshold register 3 (ADC_TR3)
         --  ADC regular sequence register 1 (ADC_SQR1)
         --  ADC regular sequence register 2 (ADC_SQR2)
         --  ADC regular sequence register 3 (ADC_SQR3)
         --  ADC regular sequence register 4 (ADC_SQR4)
         --  ADC injected sequence register (ADC_JSQR)
         --  ADC offset y register (ADC_OFRy)
         --  ADC analog watchdog 2 configuration register (ADC_AWD2CR)
         --  ADC analog watchdog 3 configuration register (ADC_AWD3CR)
         --  ADC differential mode selection register (ADC_DIFSEL)
         --  ADC calibration factors (ADC_CALFACT)
         --  ADC Gain compensation Register (ADC_GCOMP)
      end Initialize_ADCx;

      ----------------------------
      -- Initialize_ADC12_Clock --
      ----------------------------

      procedure Initialize_ADC12_Clock is
      begin
         --  A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_APB1ENR1.PWREN :=
         --    A0B.STM32G474.SVD.RCC.B_0x1;
         --  A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_APB2ENR.SYSCFGEN :=
         --    A0B.STM32G474.SVD.RCC.B_0x1;

         --  System clock (150 MHz) is used as source clock for ADC.

         A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_CCIPR.ADC12SEL :=
           A0B.STM32G474.SVD.RCC.B_0x2;
         --  System clock selected as ADC1/2 clock
         A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_AHB2ENR.ADC12EN :=
           A0B.STM32G474.SVD.RCC.B_0x1;
      end Initialize_ADC12_Clock;

      -----------------------------
      -- Initialize_ADC12_Common --
      -----------------------------

      procedure Initialize_ADC12_Common is
      begin
         --  ADC12 common control register (ADC12_CCR)

         declare
            Value : A0B.STM32G474.SVD.ADC.CCR_Register
              := A0B.STM32G474.SVD.ADC.ADC12_Common_Periph.CCR;

         begin
            Value.DUAL      := 2#00000#;  --  00000: Independent mode
            Value.DELAY_k   := 2#0000#;   --  <>
            Value.DMACFG    := False;     --  0: DMA One Shot mode selected
            Value.MDMA      := 2#00#;     --  00: MDMA mode disabled
            Value.CKMODE    := 2#11#;
            --  11: adc_hclk/4 (Synchronous clock mode)
            Value.PRESC     := 2#00000#;  --  0000: input ADC clock not divided
            Value.VREFEN    := False;     --  0: VREFINT channel disabled
            Value.VSENSESEL := False;
            --  0: Temperature sensor channel disabled
            Value.VBATSEL   := False;
            --  0: VBAT channel disabled.

            A0B.STM32G474.SVD.ADC.ADC12_Common_Periph.CCR := Value;
         end;
      end Initialize_ADC12_Common;

      ---------------
      -- Start_ADC --
      ---------------

      procedure Start_ADC
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral) is
      begin
         ADC.CR :=
           (ADSTART => True, ADVREGEN => True, DEEPPWD => False, others => <>);
      end Start_ADC;

      --------------------------
      -- Start_ADC_Operations --
      --------------------------

      procedure Start_ADC_Operations
        (ADC : in out A0B.STM32G474.SVD.ADC.ADC1_Peripheral)
      is
         CPU_Cycles_Per_Microsecond : constant := CPU_Frequency / 1_000_000;
         T_Start_Vrefint            : constant := 12;
         --  Start time of reference voltage buffer when ADC is enable,
         --  microseconds
         Start_Vrefint_Cycles       : constant :=
           CPU_Cycles_Per_Microsecond * T_Start_Vrefint;

      begin
         ADC.CR := (DEEPPWD => False, others => <>);
         ADC.CR := (DEEPPWD => False, ADVREGEN => True, others => <>);

         for J in 1 .. Start_Vrefint_Cycles loop
            null;
         end loop;
      end Start_ADC_Operations;

   begin
      Initialize_ADC12_Clock;
      Initialize_ADC1;
      Initialize_ADC2;
      Initialize_ADC12_Common;

      Start_ADC_Operations (A0B.STM32G474.SVD.ADC.ADC1_Periph);
      Calibrate_Single_Ended (A0B.STM32G474.SVD.ADC.ADC1_Periph);
      Enable_ADC (A0B.STM32G474.SVD.ADC.ADC1_Periph);
      Start_ADC (A0B.STM32G474.SVD.ADC.ADC1_Periph);
      --  Start ADC. Conversions will be started on signal from the timer.

      Start_ADC_Operations (A0B.STM32G474.SVD.ADC.ADC2_Periph);
      Calibrate_Single_Ended (A0B.STM32G474.SVD.ADC.ADC2_Periph);
      Enable_ADC (A0B.STM32G474.SVD.ADC.ADC2_Periph);
      Start_ADC (A0B.STM32G474.SVD.ADC.ADC2_Periph);
      --  Start ADC. Conversions will be started on signal from the timer.
   end Initialize_ADC;

   -----------------------------
   -- Initialize_Console_UART --
   -----------------------------

   procedure Initialize_Console_UART is
      Config : constant
        Configuration.My_H7_USART.H7_UART_Configuration :=
          (Word_Length => 8,
           Parity      => Configuration.My_F0_USART.None,
           Stop_Bits   => Configuration.My_F0_USART.Stop_1,
           USARTDIV    => 1_302,  --  115_200 baud
           PRESCALER   => 0);

   begin
      Console_UART.Initialize (Config);
      Console_UART.Enable;
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt
        (A0B.STM32G474.Interrupts.USART1);
   end Initialize_Console_UART;

   --------------------
   -- Initialize_DMA --
   --------------------

   procedure Initialize_DMA is
   begin
      ADC1_DMA_CH.DMA_CH.Initialize;
      ADC1_DMA_CH.DMA_CH.Configure_Peripheral_To_Memory
        (Priority             => A0B.STM32_DMA.Very_High,
         Peripheral_Address   => A0B.STM32G474.SVD.ADC.ADC1_Periph.DR'Address,
         Peripheral_Data_Size => A0B.STM32_DMA.Half_Word,
         Memory_Data_Size     => A0B.STM32_DMA.Half_Word,
         Circular_Mode        => True);

      ADC2_DMA_CH.DMA_CH.Initialize;
      ADC2_DMA_CH.DMA_CH.Configure_Peripheral_To_Memory
        (Priority             => A0B.STM32_DMA.Very_High,
         Peripheral_Address   => A0B.STM32G474.SVD.ADC.ADC2_Periph.DR'Address,
         Peripheral_Data_Size => A0B.STM32_DMA.Half_Word,
         Memory_Data_Size     => A0B.STM32_DMA.Half_Word,
         Circular_Mode        => True);
   end Initialize_DMA;

   ---------------------
   -- Initialize_GPIO --
   ---------------------

   procedure Initialize_GPIO is
   begin
      --  ADC1/ADC2 input

      M1_P_Pin.Initialize_Analog;
      M1_C_Pin.Initialize_Analog;
      M2_P_Pin.Initialize_Analog;
      M2_C_Pin.Initialize_Analog;
      M3_P_Pin.Initialize_Analog;
      M3_C_Pin.Initialize_Analog;

      --  TIM2 output

      M1_IN1_Pin.Initialize_Alternative_Function
        (Line  => A0B.STM32.TIM_Lines.TIM2_CH1,
         Mode  => A0B.STM32G474.GPIO.Push_Pull,
         Speed => A0B.STM32G474.GPIO.Very_High,
         Pull  => A0B.STM32G474.GPIO.Pull_Up);
      M1_IN2_Pin.Initialize_Alternative_Function
        (Line  => A0B.STM32.TIM_Lines.TIM2_CH2,
         Mode  => A0B.STM32G474.GPIO.Push_Pull,
         Speed => A0B.STM32G474.GPIO.Very_High,
         Pull  => A0B.STM32G474.GPIO.Pull_Up);

      --  TIM3 output

      M2_IN1_Pin.Initialize_Alternative_Function
        (Line  => A0B.STM32.TIM_Lines.TIM3_CH1,
         Mode  => A0B.STM32G474.GPIO.Push_Pull,
         Speed => A0B.STM32G474.GPIO.Very_High,
         Pull  => A0B.STM32G474.GPIO.Pull_Up);
      M2_IN2_Pin.Initialize_Alternative_Function
        (Line  => A0B.STM32.TIM_Lines.TIM3_CH2,
         Mode  => A0B.STM32G474.GPIO.Push_Pull,
         Speed => A0B.STM32G474.GPIO.Very_High,
         Pull  => A0B.STM32G474.GPIO.Pull_Up);

      --  TIM4 output

      M3_IN1_Pin.Initialize_Alternative_Function
        (Line  => A0B.STM32.TIM_Lines.TIM4_CH1,
         Mode  => A0B.STM32G474.GPIO.Push_Pull,
         Speed => A0B.STM32G474.GPIO.Very_High,
         Pull  => A0B.STM32G474.GPIO.Pull_Up);
      M3_IN2_Pin.Initialize_Alternative_Function
        (Line  => A0B.STM32.TIM_Lines.TIM4_CH2,
         Mode  => A0B.STM32G474.GPIO.Push_Pull,
         Speed => A0B.STM32G474.GPIO.Very_High,
         Pull  => A0B.STM32G474.GPIO.Pull_Up);

      --  USART's input/output pins are configured by the USART driver
   end Initialize_GPIO;

   ----------------------
   -- Initialize_OPAMP --
   ----------------------

   procedure Initialize_OPAMP is
      OPAMP : A0B.STM32G474.SVD.OPAMP.OPAMP_Peripheral
        renames A0B.STM32G474.SVD.OPAMP.OPAMP_Periph;

   begin
      A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_APB2ENR.SYSCFGEN :=
        A0B.STM32G474.SVD.RCC.B_0x1;

      --  OPAMP1 control/status register (OPAMP1_CSR)

      declare
         Value : A0B.STM32G474.SVD.OPAMP.OPAMP1_CSR_Register :=
           OPAMP.OPAMP1_CSR;

      begin
         Value.OPAEN     := False;  --  0: Operational amplifier disabled
         Value.FORCE_VP  := False;
         --  0: Normal operating mode. Non-inverting input connected to inputs.
         Value.VP_SEL    := 2#01#;
         --  01: VINP1 pin connected to OPAMP1 VINP input (PA3)
         Value.USERTRIM  := False;  --  0: ‘factory’ trim code used
         Value.VM_SEL    := 2#10#;
         --  10: Feedback resistor is connected to OPAMP VINM input (PGA mode),
         --  Inverting input selection is depends on the PGA_GAIN setting
         Value.OPAHSM    := True;
         --  1: Operational amplifier in high-speed mode
         Value.OPAINTOEN := True;
         --  1: The OPAMP output is connected internally to an ADC channel and
         --  disconnected from the output pin
         Value.CALON     := False;
         --  0: Normal mode
         Value.CALSEL    := 2#00#;  --  <>
         Value.PGA_GAIN  := 2#00001#;
         --  00001: Non inverting internal gain = 4
         --  Value.TRIMOFFSETP := <>  Factory value
         --  Value.TRIMOFFSETN := <>  Factory value
         --  Value.CALOUT             Read only
         Value.LOCK      := False;  --  0: OPAMP1_CSR is read-write

         OPAMP.OPAMP1_CSR := Value;
      end;

      --  OPAMP2 control/status register (OPAMP2_CSR)

      declare
         Value : A0B.STM32G474.SVD.OPAMP.OPAMP2_CSR_Register :=
           OPAMP.OPAMP2_CSR;

      begin
         Value.OPAEN     := False;  --  0: Operational amplifier disabled
         Value.FORCE_VP  := False;
         --  0: Normal operating mode. Non-inverting input connected to inputs.
         Value.VP_SEL    := 2#00#;
         --  00: VINP0 pin connected to OPAMP2 VINP input (PA7)
         Value.USERTRIM  := False;  --  0: ‘factory’ trim code used
         Value.VM_SEL    := 2#10#;
         --  10: Feedback resistor is connected to OPAMP VINM input (PGA mode),
         --  Inverting input selection is depends on the PGA_GAIN setting
         Value.OPAHSM    := True;
         --  1: Operational amplifier in high-speed mode
         Value.OPAINTOEN := True;
         --  1: The OPAMP output is connected internally to an ADC channel and
         --  disconnected from the output pin
         Value.CALON     := False;
         --  0: Normal mode
         Value.CALSEL    := 2#00#;  --  <>
         Value.PGA_GAIN  := 2#00001#;
         --  00001: Non inverting internal gain = 4
         --  Value.TRIMOFFSETP := <>  Factory value
         --  Value.TRIMOFFSETN := <>  Factory value
         --  Value.CALOUT             Read only
         Value.LOCK      := False;  --  0: OPAMP1_CSR is read-write

         OPAMP.OPAMP2_CSR := Value;
      end;

      --  OPAMP3 control/status register (OPAMP3_CSR)

      declare
         Value : A0B.STM32G474.SVD.OPAMP.OPAMP3_CSR_Register :=
           OPAMP.OPAMP3_CSR;

      begin
         Value.OPAEN     := False;  --  0: Operational amplifier disabled
         Value.FORCE_VP  := False;
         --  0: Normal operating mode. Non-inverting input connected to inputs.
         Value.VP_SEL    := 2#00#;
         --  10: VINP2 pin connected to OPAMP3 VINP input (PA3)
         Value.USERTRIM  := False;  --  0: ‘factory’ trim code used
         Value.VM_SEL    := 2#10#;
         --  10: Feedback resistor is connected to OPAMP VINM input (PGA mode),
         --  Inverting input selection is depends on the PGA_GAIN setting
         Value.OPAHSM    := True;
         --  1: Operational amplifier in high-speed mode
         Value.OPAINTOEN := True;
         --  1: The OPAMP output is connected internally to an ADC channel and
         --  disconnected from the output pin
         Value.CALON     := False;
         --  0: Normal mode
         Value.CALSEL    := 2#00#;  --  <>
         Value.PGA_GAIN  := 2#00001#;
         --  00001: Non inverting internal gain = 4
         --  Value.TRIMOFFSETP := <>  Factory value
         --  Value.TRIMOFFSETN := <>  Factory value
         --  Value.CALOUT             Read only
         Value.LOCK      := False;  --  0: OPAMP1_CSR is read-write

         OPAMP.OPAMP3_CSR := Value;
      end;

      --  Enable OPAMPs

      OPAMP.OPAMP1_CSR.OPAEN := True;
      OPAMP.OPAMP2_CSR.OPAEN := True;
      OPAMP.OPAMP3_CSR.OPAEN := True;
   end Initialize_OPAMP;

   ----------------------
   -- Initialize_TIM15 --
   ----------------------

   procedure Initialize_TIM15 is
      TIM : A0B.STM32G474.SVD.TIM.TIM15_Peripheral
        renames A0B.STM32G474.SVD.TIM.TIM15_Periph;

   begin
      A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_APB2ENR.TIM15EN :=
        A0B.STM32G474.SVD.RCC.B_0x1;

      --  TIM15 control register 1 (TIM15_CR1)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR1_Register_2 := TIM.CR1;

      begin
         Value.CEN    := False;  --  0: Counter disabled
         Value.UDIS   := False;
         --  0: UEV enabled. The Update (UEV) event is generated by one of the
         --  following events:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         --  Buffered registers are then loaded with their preload values.
         Value.URS    := False;
         --  0: Any of the following events generate an update interrupt if
         --  enabled. These events can be:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         Value.OPM    := False;  --  0: Counter is not stopped at update event
         Value.ARPE   := False;  --  0: TIM15_ARR register is not buffered
         Value.CKD    := 2#00#;  --  00: tDTS = ttim_ker_ck
         Value.UIFREMAP := False;
         --  0: No remapping. UIF status bit is not copied to TIM15_CNT
         --  register bit 31.
         Value.DITHEN := False;  --  0: Dithering disabled

         A0B.STM32G474.SVD.TIM.TIM15_Periph.CR1 := Value;
      end;

      --  TIM15 control register 2 (TIM15_CR2)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR2_Register_2 := TIM.CR2;

      begin
         Value.CCPC  := False;
         --  <> 0: CCxE, CCxNE and OCxM bits are not preloaded
         Value.CCUS  := False;
         --  <> 0: When capture/compare control bits are preloaded (CCPC=1),
         --  they are updated by setting the COMG bit only.
         Value.CCDS  := False;
         --  <> 0: CCx DMA request sent when CCx event occurs
         Value.MMS   := 2#010#;
         --  010: Update - The update event is selected as trigger output
         --  (tim_trgo). For instance a master timer can then be used as a
         --  prescaler for a slave timer.
         --
         --  XXX PWM might be used to move start of ADC a bit after start of
         --  PWM cycle of motor control.
         Value.TI1S  := False;
         --  0: The tim_ti1_in[15:0] multiplexer output is connected to tim_ti1
         --  input
         Value.OIS1  := False;
         --  <> 0: tim_oc1=0 after a dead-time when MOE=0
         Value.OIS1N := False;
         --  <> 0: tim_oc1n=0 after a dead-time when MOE=0
         Value.OIS2  := False;
         --  <> 0: tim_oc2=0 when MOE=0

         TIM.CR2 := Value;
      end;

      --  TIM15 slave mode control register (TIM15_SMCR)

      declare
         Value : A0B.STM32G474.SVD.TIM.SMCR_Register_1 := TIM.SMCR;

      begin
         Value.SMS    := 2#110#;
         Value.SMS_3  := False;
         --  0110: Trigger Mode - The counter starts at a rising edge of the
         --  trigger tim_trgi (but it is not reset). Only the start of the
         --  counter is controlled.
         Value.TS     := 2#001#;
         Value.TS_4_3 := 2#00#;
         --  00001: Internal Trigger 1 (tim_itr1) connected to tim2_trgo
         Value.MSM    := False;  --  0: No action
         --  Value.SMSPE - undefined in SVD

         TIM.SMCR := Value;
      end;

      --  TIM15 DMA/interrupt enable register (TIM15_DIER)
      --  TIM15 status register (TIM15_SR)
      --  TIM15 event generation register (TIM15_EGR)
      --  TIM15 capture/compare mode register 1 (TIM15_CCMR1)
      --  TIM15 capture/compare enable register (TIM15_CCER)

      --  TIM15 counter (TIM15_CNT)

      TIM.CNT.CNT := 0;

      --  TIM15 prescaler (TIM15_PSC)

      TIM.PSC.PSC := ADC_PWM_TIM_Prescaler - 1;

      --  TIM15 auto-reload register (TIM15_ARR)

      TIM.ARR.ARR := ADC_TIM_Cycles - 1;

      --  TIM15 repetition counter register (TIM15_RCR)
      --  TIM15 capture/compare register 1 (TIM15_CCR1)
      --  TIM15 capture/compare register 2 (TIM15_CCR2)
      --  TIM15 break and dead-time register (TIM15_BDTR)
      --  TIM15 timer deadtime register 2 (TIM15_DTR2)
      --  TIM15 input selection register (TIM15_TISEL)
      --  TIM15 alternate function register 1 (TIM15_AF1)
      --  TIM15 alternate function register 2 (TIM15_AF2)
      --  TIM15 DMA control register (TIM15_DCR)
      --  TIM15 DMA address for full transfer (TIM15_DMAR)
   end Initialize_TIM15;

   ---------------------
   -- Initialize_TIM2 --
   ---------------------

   procedure Initialize_TIM2 is
      TIM : A0B.STM32G474.SVD.TIM.TIM1_Peripheral
        renames A0B.STM32G474.SVD.TIM.TIM2_Periph;

   begin
      A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_APB1ENR1.TIM2EN :=
        A0B.STM32G474.SVD.RCC.B_0x1;

      --  TIMx control register 1 (TIMx_CR1)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR1_Register := TIM.CR1;

      begin
         Value.CEN      := False;  --  0: Counter disabled
         Value.UDIS     := False;
         --  0: UEV enabled. The Update (UEV) event is generated by one of the
         --  following events:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         --  Buffered registers are then loaded with their preload values.
         Value.URS      := False;
         --  0: Any of the following events generate an update interrupt or DMA
         --  request if enabled. These events can be:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         Value.OPM      := False;
         --  0: Counter is not stopped at update event
         Value.DIR      := False;  --  0: Counter used as upcounter
         Value.CMS      := 2#00#;
         --  00: Edge-aligned mode. The counter counts up or down depending on
         --  the direction bit (DIR).
         Value.ARPE     := False;
         --  0: TIMx_ARR register is not buffered.
         --  It is set to True later, after set of initial values.
         Value.CKD      := 2#00#;  --  00: tDTS = ttim_ker_ck
         Value.UIFREMAP := False;
         --  0: No remapping. UIF status bit is not copied to TIMx_CNT register
         --  bit 31.
         Value.DITHEN   := False;  --  0: Dithering disabled

         TIM.CR1 := Value;
      end;

      --  TIMx control register 2 (TIMx_CR2)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR2_Register := TIM.CR2;

      begin
         Value.CCDS := True;
         --  <> 1: CCx DMA requests sent when update event occurs
         Value.MMS   := 2#001#;
         Value.MMS_3 := False;
         --  0001: Enable - the Counter enable signal, CNT_EN, is used as
         --  trigger output (tim_trgo). It is useful to start several timers
         --  at the same time or to control a window in which a slave timer
         --  is enabled. The Counter Enable signal is generated by a logic AND
         --  between CEN control bit and the trigger input when configured in
         --  gated mode.
         --
         --  When the Counter Enable signal is controlled by the trigger input,
         --  there is a delay on tim_trgo, except if the master/slave mode is
         --  selected (see the MSM bit description in TIMx_SMCR register).
         Value.TI1S  := False;
         --  0: The tim_ti1_in[15:0] multiplexer output is to tim_ti1 input

         TIM.CR2 := Value;
      end;

      --  TIMx slave mode control register (TIMx_SMCR)

      declare
         Value : A0B.STM32G474.SVD.TIM.SMCR_Register := TIM.SMCR;

      begin
         Value.SMS    := 2#000#;
         Value.SMS_3  := False;
         --  0000: Slave mode disabled - if CEN = ‘1 then the prescaler is
         --  clocked directly by the internal clock.
         Value.OCCS   := False;
         --  0: tim_ocref_clr_int is connected to the tim_ocref_clr input
         Value.TS     := 2#000#;
         Value.TS_4_3 := 2#00#;
         --  <> 00000: Internal trigger 0 (tim_itr0)
         Value.MSM    := True;
         --  1: The effect of an event on the trigger input (tim_trgi) is
         --  delayed to allow a perfect synchronization between the current
         --  timer and its slaves (through tim_trgo). It is useful if we want
         --  to synchronize several timers on a single external event.
         Value.ETF    := 2#0000#;
         --  <> 0000: No filter, sampling is done at fDTS
         Value.ETPS   := 2#00#;     --  <> 00: Prescaler OFF
         Value.ECE    := False;     --  <> 0: External clock mode 2 disabled
         Value.ETP    := False;
         --  <> 0: tim_etr_in is non-inverted, active at high level or rising
         --  edge
         Value.SMSPE  := False;     --  0: SMS[3:0] bitfield is not preloaded
         Value.SMSPS  := False;
         --  0: The transfer is triggered by the Timer’s Update event

         TIM.SMCR := Value;
      end;

      --  TIMx DMA/Interrupt enable register (TIMx_DIER)
      --  TIMx status register (TIMx_SR)
      --  TIMx event generation register (TIMx_EGR)

      --  TIMx capture/compare mode register 1 (TIMx_CCMR1)

      declare
         Value : A0B.STM32G474.SVD.TIM.CCMR1_Output_Register :=
           TIM.CCMR1_Output;

      begin
         Value.CC1S   := 2#00#;  --  00: CC1 channel is configured as output
         Value.OC1FE  := False;
         --  0: CC1 behaves normally depending on counter and CCR1 values even
         --  when the trigger is ON. The minimum delay to activate CC1 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Value.OC1PE  := False;
         --  0: Preload register on TIMx_CCR1 disabled. TIMx_CCR1 can be
         --  written at anytime, the new value is taken in account immediately.
         --  It is set to True later.
         Value.OC1M   := 2#110#;
         Value.OC1M_3 := False;
         --  0110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR1 else inactive. In downcounting, channel 1 is
         --  inactive (tim_oc1ref=0) as long as TIMx_CNT>TIMx_CCR1 else active
         --  (tim_oc1ref=1).
         Value.OC1CE  := False;
         --  0: tim_oc1ref is not affected by the tim_ocref_clr_int input

         Value.CC2S   := 2#00#;  --  00: CC2 channel is configured as output
         Value.OC2FE  := False;
         --  0: CC2 behaves normally depending on counter and CCR2 values even
         --  when the trigger is ON. The minimum delay to activate CC2 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Value.OC2PE  := False;
         --  0: Preload register on TIMx_CCR2 disabled. TIMx_CCR2 can be
         --  written at anytime, the new value is taken in account immediately.
         --  It is set to True later.
         Value.OC2M   := 2#110#;
         Value.OC2M_3 := False;
         --  0110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR2 else inactive. In downcounting, channel 2 is
         --  inactive (tim_oc2ref=0) as long as TIMx_CNT>TIMx_CCR2 else active
         --  (tim_oc2ref=1).
         Value.OC2CE  := False;
         --  0: tim_oc2ref is not affected by the tim_ocref_clr_int input

         TIM.CCMR1_Output := Value;
      end;

      --  TIMx capture/compare mode register 2 (TIMx_CCMR2)

      --  TIMx capture/compare enable register (TIMx_CCER)

      declare
         Value : A0B.STM32G474.SVD.TIM.CCER_Register := TIM.CCER;

      begin
         Value.CC1E  := True;
         --  1: Capture mode enabled / OC1 signal is output on the
         --  corresponding output pin
         Value.CC1P  := False;
         --  0: OC1 active high (output mode) / Edge sensitivity selection
         --  (input mode, see below)
         Value.CC1NP := False;
         --  CC1 channel configured as output: CC1NP must be kept cleared in
         --  this case.

         Value.CC2E  := True;
         --  1: Capture mode enabled / OC2 signal is output on the
         --  corresponding output pin
         Value.CC2P  := False;
         --  0: OC2 active high (output mode) / Edge sensitivity selection
         --  (input mode, see below)
         Value.CC2NP := False;
         --  CC2 channel configured as output: CC2NP must be kept cleared in
         --  this case.

         TIM.CCER := Value;
      end;

      --  TIMx counter (TIMx_CNT)

      TIM.CNT := (CNT => 0, Reserved_16_30 => 0, UIFCPY => False);
      --  XXX SVD: invalid mapping, TIM2 is 32bit timer

      --  TIMx prescaler (TIMx_PSC)

      TIM.PSC.PSC := ADC_PWM_TIM_Prescaler - 1;

      --  TIMx auto-reload register (TIMx_ARR)

      TIM.ARR := (ARR => PWM_TIM_Cycles - 1, Reserved_16_31 => 0);
      --  XXX SVD: invalid mapping, TIM2 is 32bit timer

      --  TIMx capture/compare register 1 (TIMx_CCR1)

      TIM.CCR1 := (CCR1 => 0, Reserved_16_31 => 0);
      --  XXX SVD: invalid mapping, TIM2 is 32bit timer

      --  TIMx capture/compare register 2 (TIMx_CCR2)

      TIM.CCR2 := (CCR2 => 0, Reserved_16_31 => 0);
      --  XXX SVD: invalid mapping, TIM2 is 32bit timer

      --  TIMx capture/compare register 3 (TIMx_CCR3)
      --  TIMx capture/compare register 4 (TIMx_CCR4)
      --  TIMx timer encoder control register (TIMx_ECR)
      --  TIMx timer input selection register (TIMx_TISEL)
      --  TIMx alternate function register 1 (TIMx_AF1)
      --  TIMx alternate function register 2 (TIMx_AF2)
      --  TIMx DMA control register (TIMx_DCR)
      --  TIMx DMA address for full transfer (TIMx_DMAR)

      --  Final setup

      TIM.CR1.ARPE := True;
      --  1: TIMx_ARR register is buffered
      --  XXX Is it necessary, will it be changed at all?

      TIM.CCMR1_Output.OC1PE := True;
      TIM.CCMR1_Output.OC2PE := True;
      --  1: Preload register on TIMx_CCR1/TIMx_CCR2 enabled. Read/Write
      --  operations access the preload register. TIMx_CCR1/TIMx_CCR2
      --  preload value is loaded in the active register at each update event.
   end Initialize_TIM2;

   ---------------------
   -- Initialize_TIM3 --
   ---------------------

   procedure Initialize_TIM3 is
      TIM : A0B.STM32G474.SVD.TIM.TIM1_Peripheral
        renames A0B.STM32G474.SVD.TIM.TIM3_Periph;

   begin
      A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_APB1ENR1.TIM3EN :=
        A0B.STM32G474.SVD.RCC.B_0x1;

      --  TIMx control register 1 (TIMx_CR1)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR1_Register := TIM.CR1;

      begin
         Value.CEN      := False;  --  0: Counter disabled
         Value.UDIS     := False;
         --  0: UEV enabled. The Update (UEV) event is generated by one of the
         --  following events:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         --  Buffered registers are then loaded with their preload values.
         Value.URS      := False;
         --  0: Any of the following events generate an update interrupt or DMA
         --  request if enabled. These events can be:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         Value.OPM      := False;
         --  0: Counter is not stopped at update event
         Value.DIR      := False;  --  0: Counter used as upcounter
         Value.CMS      := 2#00#;
         --  00: Edge-aligned mode. The counter counts up or down depending on
         --  the direction bit (DIR).
         Value.ARPE     := False;
         --  0: TIMx_ARR register is not buffered.
         --  It is set to True later, after set of initial values.
         Value.CKD      := 2#00#;  --  00: tDTS = ttim_ker_ck
         Value.UIFREMAP := False;
         --  0: No remapping. UIF status bit is not copied to TIMx_CNT register
         --  bit 31.
         Value.DITHEN   := False;  --  0: Dithering disabled

         TIM.CR1 := Value;
      end;

      --  TIMx control register 2 (TIMx_CR2)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR2_Register := TIM.CR2;

      begin
         Value.CCDS := True;
         --  <> 1: CCx DMA requests sent when update event occurs
         Value.MMS   := 2#000#;
         Value.MMS_3 := False;
         --  <> 0000: Reset - the UG bit from the TIMx_EGR register is used
         --  as trigger output (tim_trgo). If the reset is generated by the
         --  trigger input (slave mode controller configured in reset mode)
         --  then the signal on tim_trgo is delayed compared to the actual
         --  reset.
         Value.TI1S  := False;
         --  0: The tim_ti1_in[15:0] multiplexer output is to tim_ti1 input

         TIM.CR2 := Value;
      end;

      --  TIMx slave mode control register (TIMx_SMCR)

      declare
         Value : A0B.STM32G474.SVD.TIM.SMCR_Register := TIM.SMCR;

      begin
         Value.SMS    := 2#110#;
         Value.SMS_3  := False;
         --  0110: Trigger Mode - The counter starts at a rising edge of the
         --  trigger tim_trgi (but it is not reset). Only the start of the
         --  counter is controlled.
         Value.OCCS   := False;
         --  0: tim_ocref_clr_int is connected to the tim_ocref_clr input
         Value.TS     := 2#001#;
         Value.TS_4_3 := 2#00#;
         --  00001: Internal Trigger 1 (tim_itr1) connected to tim2_trgo
         Value.MSM    := False;  --  0: No action
         Value.ETF    := 2#0000#;
         --  <> 0000: No filter, sampling is done at fDTS
         Value.ETPS   := 2#00#;     --  <> 00: Prescaler OFF
         Value.ECE    := False;     --  <> 0: External clock mode 2 disabled
         Value.ETP    := False;
         --  <> 0: tim_etr_in is non-inverted, active at high level or rising
         --  edge
         Value.SMSPE  := False;     --  0: SMS[3:0] bitfield is not preloaded
         Value.SMSPS  := False;
         --  0: The transfer is triggered by the Timer’s Update event

         TIM.SMCR := Value;
      end;

      --  TIMx DMA/Interrupt enable register (TIMx_DIER)
      --  TIMx status register (TIMx_SR)
      --  TIMx event generation register (TIMx_EGR)

      --  TIMx capture/compare mode register 1 (TIMx_CCMR1)

      declare
         Value : A0B.STM32G474.SVD.TIM.CCMR1_Output_Register :=
           TIM.CCMR1_Output;

      begin
         Value.CC1S   := 2#00#;  --  00: CC1 channel is configured as output
         Value.OC1FE  := False;
         --  0: CC1 behaves normally depending on counter and CCR1 values even
         --  when the trigger is ON. The minimum delay to activate CC1 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Value.OC1PE  := False;
         --  0: Preload register on TIMx_CCR1 disabled. TIMx_CCR1 can be
         --  written at anytime, the new value is taken in account immediately.
         --  It is set to True later.
         Value.OC1M   := 2#110#;
         Value.OC1M_3 := False;
         --  0110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR1 else inactive. In downcounting, channel 1 is
         --  inactive (tim_oc1ref=0) as long as TIMx_CNT>TIMx_CCR1 else active
         --  (tim_oc1ref=1).
         Value.OC1CE  := False;
         --  0: tim_oc1ref is not affected by the tim_ocref_clr_int input

         Value.CC2S   := 2#00#;  --  00: CC2 channel is configured as output
         Value.OC2FE  := False;
         --  0: CC2 behaves normally depending on counter and CCR2 values even
         --  when the trigger is ON. The minimum delay to activate CC2 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Value.OC2PE  := False;
         --  0: Preload register on TIMx_CCR2 disabled. TIMx_CCR2 can be
         --  written at anytime, the new value is taken in account immediately.
         --  It is set to True later.
         Value.OC2M   := 2#110#;
         Value.OC2M_3 := False;
         --  0110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR2 else inactive. In downcounting, channel 2 is
         --  inactive (tim_oc2ref=0) as long as TIMx_CNT>TIMx_CCR2 else active
         --  (tim_oc2ref=1).
         Value.OC2CE  := False;
         --  0: tim_oc2ref is not affected by the tim_ocref_clr_int input

         TIM.CCMR1_Output := Value;
      end;

      --  TIMx capture/compare mode register 2 (TIMx_CCMR2)

      --  TIMx capture/compare enable register (TIMx_CCER)

      declare
         Value : A0B.STM32G474.SVD.TIM.CCER_Register := TIM.CCER;

      begin
         Value.CC1E  := True;
         --  1: Capture mode enabled / OC1 signal is output on the
         --  corresponding output pin
         Value.CC1P  := False;
         --  0: OC1 active high (output mode) / Edge sensitivity selection
         --  (input mode, see below)
         Value.CC1NP := False;
         --  CC1 channel configured as output: CC1NP must be kept cleared in
         --  this case.

         Value.CC2E  := True;
         --  1: Capture mode enabled / OC2 signal is output on the
         --  corresponding output pin
         Value.CC2P  := False;
         --  0: OC2 active high (output mode) / Edge sensitivity selection
         --  (input mode, see below)
         Value.CC2NP := False;
         --  CC2 channel configured as output: CC2NP must be kept cleared in
         --  this case.

         TIM.CCER := Value;
      end;

      --  TIMx counter (TIMx_CNT)

      TIM.CNT.CNT := 0;

      --  TIMx prescaler (TIMx_PSC)

      TIM.PSC.PSC := ADC_PWM_TIM_Prescaler - 1;

      --  TIMx auto-reload register (TIMx_ARR)

      TIM.ARR.ARR := PWM_TIM_Cycles - 1;

      --  TIMx capture/compare register 1 (TIMx_CCR1)

      TIM.CCR1.CCR1 := 0;

      --  TIMx capture/compare register 2 (TIMx_CCR2)

      TIM.CCR2.CCR2 := 0;

      --  TIMx capture/compare register 3 (TIMx_CCR3)
      --  TIMx capture/compare register 4 (TIMx_CCR4)
      --  TIMx timer encoder control register (TIMx_ECR)
      --  TIMx timer input selection register (TIMx_TISEL)
      --  TIMx alternate function register 1 (TIMx_AF1)
      --  TIMx alternate function register 2 (TIMx_AF2)
      --  TIMx DMA control register (TIMx_DCR)
      --  TIMx DMA address for full transfer (TIMx_DMAR)

      --  Final setup

      TIM.CR1.ARPE := True;
      --  1: TIMx_ARR register is buffered
      --  XXX Is it necessary, will it be changed at all?

      TIM.CCMR1_Output.OC1PE := True;
      TIM.CCMR1_Output.OC2PE := True;
      --  1: Preload register on TIMx_CCR1/TIMx_CCR2 enabled. Read/Write
      --  operations access the preload register. TIMx_CCR1/TIMx_CCR2
      --  preload value is loaded in the active register at each update event.
   end Initialize_TIM3;

   ---------------------
   -- Initialize_TIM4 --
   ---------------------

   procedure Initialize_TIM4 is
      TIM : A0B.STM32G474.SVD.TIM.TIM1_Peripheral
        renames A0B.STM32G474.SVD.TIM.TIM4_Periph;

   begin
      A0B.STM32G474.SVD.RCC.RCC_Periph.RCC_APB1ENR1.TIM4EN :=
        A0B.STM32G474.SVD.RCC.B_0x1;

      --  TIMx control register 1 (TIMx_CR1)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR1_Register := TIM.CR1;

      begin
         Value.CEN      := False;  --  0: Counter disabled
         Value.UDIS     := False;
         --  0: UEV enabled. The Update (UEV) event is generated by one of the
         --  following events:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         --  Buffered registers are then loaded with their preload values.
         Value.URS      := False;
         --  0: Any of the following events generate an update interrupt or DMA
         --  request if enabled. These events can be:
         --    – Counter overflow/underflow
         --    – Setting the UG bit
         --    – Update generation through the slave mode controller
         Value.OPM      := False;
         --  0: Counter is not stopped at update event
         Value.DIR      := False;  --  0: Counter used as upcounter
         Value.CMS      := 2#00#;
         --  00: Edge-aligned mode. The counter counts up or down depending on
         --  the direction bit (DIR).
         Value.ARPE     := False;
         --  0: TIMx_ARR register is not buffered.
         --  It is set to True later, after set of initial values.
         Value.CKD      := 2#00#;  --  00: tDTS = ttim_ker_ck
         Value.UIFREMAP := False;
         --  0: No remapping. UIF status bit is not copied to TIMx_CNT register
         --  bit 31.
         Value.DITHEN   := False;  --  0: Dithering disabled

         TIM.CR1 := Value;
      end;

      --  TIMx control register 2 (TIMx_CR2)

      declare
         Value : A0B.STM32G474.SVD.TIM.CR2_Register := TIM.CR2;

      begin
         Value.CCDS := True;
         --  <> 1: CCx DMA requests sent when update event occurs
         Value.MMS   := 2#000#;
         Value.MMS_3 := False;
         --  <> 0000: Reset - the UG bit from the TIMx_EGR register is used
         --  as trigger output (tim_trgo). If the reset is generated by the
         --  trigger input (slave mode controller configured in reset mode)
         --  then the signal on tim_trgo is delayed compared to the actual
         --  reset.
         Value.TI1S  := False;
         --  0: The tim_ti1_in[15:0] multiplexer output is to tim_ti1 input

         TIM.CR2 := Value;
      end;

      --  TIMx slave mode control register (TIMx_SMCR)

      declare
         Value : A0B.STM32G474.SVD.TIM.SMCR_Register := TIM.SMCR;

      begin
         Value.SMS    := 2#110#;
         Value.SMS_3  := False;
         --  0110: Trigger Mode - The counter starts at a rising edge of the
         --  trigger tim_trgi (but it is not reset). Only the start of the
         --  counter is controlled.
         Value.OCCS   := False;
         --  0: tim_ocref_clr_int is connected to the tim_ocref_clr input
         Value.TS     := 2#001#;
         Value.TS_4_3 := 2#00#;
         --  00001: Internal Trigger 1 (tim_itr1) connected to tim2_trgo
         Value.MSM    := False;  --  0: No action
         Value.ETF    := 2#0000#;
         --  <> 0000: No filter, sampling is done at fDTS
         Value.ETPS   := 2#00#;     --  <> 00: Prescaler OFF
         Value.ECE    := False;     --  <> 0: External clock mode 2 disabled
         Value.ETP    := False;
         --  <> 0: tim_etr_in is non-inverted, active at high level or rising
         --  edge
         Value.SMSPE  := False;     --  0: SMS[3:0] bitfield is not preloaded
         Value.SMSPS  := False;
         --  0: The transfer is triggered by the Timer’s Update event

         TIM.SMCR := Value;
      end;

      --  TIMx DMA/Interrupt enable register (TIMx_DIER)
      --  TIMx status register (TIMx_SR)
      --  TIMx event generation register (TIMx_EGR)

      --  TIMx capture/compare mode register 1 (TIMx_CCMR1)

      declare
         Value : A0B.STM32G474.SVD.TIM.CCMR1_Output_Register :=
           TIM.CCMR1_Output;

      begin
         Value.CC1S   := 2#00#;  --  00: CC1 channel is configured as output
         Value.OC1FE  := False;
         --  0: CC1 behaves normally depending on counter and CCR1 values even
         --  when the trigger is ON. The minimum delay to activate CC1 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Value.OC1PE  := False;
         --  0: Preload register on TIMx_CCR1 disabled. TIMx_CCR1 can be
         --  written at anytime, the new value is taken in account immediately.
         --  It is set to True later.
         Value.OC1M   := 2#110#;
         Value.OC1M_3 := False;
         --  0110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR1 else inactive. In downcounting, channel 1 is
         --  inactive (tim_oc1ref=0) as long as TIMx_CNT>TIMx_CCR1 else active
         --  (tim_oc1ref=1).
         Value.OC1CE  := False;
         --  0: tim_oc1ref is not affected by the tim_ocref_clr_int input

         Value.CC2S   := 2#00#;  --  00: CC2 channel is configured as output
         Value.OC2FE  := False;
         --  0: CC2 behaves normally depending on counter and CCR2 values even
         --  when the trigger is ON. The minimum delay to activate CC2 output
         --  when an edge occurs on the trigger input is 5 clock cycles.
         Value.OC2PE  := False;
         --  0: Preload register on TIMx_CCR2 disabled. TIMx_CCR2 can be
         --  written at anytime, the new value is taken in account immediately.
         --  It is set to True later.
         Value.OC2M   := 2#110#;
         Value.OC2M_3 := False;
         --  0110: PWM mode 1 - In upcounting, channel 1 is active as long as
         --  TIMx_CNT<TIMx_CCR2 else inactive. In downcounting, channel 2 is
         --  inactive (tim_oc2ref=0) as long as TIMx_CNT>TIMx_CCR2 else active
         --  (tim_oc2ref=1).
         Value.OC2CE  := False;
         --  0: tim_oc2ref is not affected by the tim_ocref_clr_int input

         TIM.CCMR1_Output := Value;
      end;

      --  TIMx capture/compare mode register 2 (TIMx_CCMR2)

      --  TIMx capture/compare enable register (TIMx_CCER)

      declare
         Value : A0B.STM32G474.SVD.TIM.CCER_Register := TIM.CCER;

      begin
         Value.CC1E  := True;
         --  1: Capture mode enabled / OC1 signal is output on the
         --  corresponding output pin
         Value.CC1P  := False;
         --  0: OC1 active high (output mode) / Edge sensitivity selection
         --  (input mode, see below)
         Value.CC1NP := False;
         --  CC1 channel configured as output: CC1NP must be kept cleared in
         --  this case.

         Value.CC2E  := True;
         --  1: Capture mode enabled / OC2 signal is output on the
         --  corresponding output pin
         Value.CC2P  := False;
         --  0: OC2 active high (output mode) / Edge sensitivity selection
         --  (input mode, see below)
         Value.CC2NP := False;
         --  CC2 channel configured as output: CC2NP must be kept cleared in
         --  this case.

         TIM.CCER := Value;
      end;

      --  TIMx counter (TIMx_CNT)

      TIM.CNT.CNT := 0;

      --  TIMx prescaler (TIMx_PSC)

      TIM.PSC.PSC := ADC_PWM_TIM_Prescaler - 1;

      --  TIMx auto-reload register (TIMx_ARR)

      TIM.ARR.ARR := PWM_TIM_Cycles - 1;

      --  TIMx capture/compare register 1 (TIMx_CCR1)

      TIM.CCR1.CCR1 := 0;

      --  TIMx capture/compare register 2 (TIMx_CCR2)

      TIM.CCR2.CCR2 := 0;

      --  TIMx capture/compare register 3 (TIMx_CCR3)
      --  TIMx capture/compare register 4 (TIMx_CCR4)
      --  TIMx timer encoder control register (TIMx_ECR)
      --  TIMx timer input selection register (TIMx_TISEL)
      --  TIMx alternate function register 1 (TIMx_AF1)
      --  TIMx alternate function register 2 (TIMx_AF2)
      --  TIMx DMA control register (TIMx_DCR)
      --  TIMx DMA address for full transfer (TIMx_DMAR)

      --  Final setup

      TIM.CR1.ARPE := True;
      --  1: TIMx_ARR register is buffered
      --  XXX Is it necessary, will it be changed at all?

      TIM.CCMR1_Output.OC1PE := True;
      TIM.CCMR1_Output.OC2PE := True;
      --  1: Preload register on TIMx_CCR1/TIMx_CCR2 enabled. Read/Write
      --  operations access the preload register. TIMx_CCR1/TIMx_CCR2
      --  preload value is loaded in the active register at each update event.
   end Initialize_TIM4;

   --------------------
   -- USART1_Handler --
   --------------------

   procedure USART1_Handler is
   begin
      Configuration.Console_UART.On_Interrupt;
   end USART1_Handler;

end Configuration;
