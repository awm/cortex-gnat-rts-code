with Ada.Interrupts.Names;
with Interfaces;
with System.Machine_Code;
with System.Storage_Elements;

package body Startup is

   --  Program_Initialization is the program entry point. It sets up
   --  the stack pointer (to _estack, created in the linker script)
   --  and calls Complete_Program_Initialization.
   --
   --  The reason for this is that if you use bossac without the -b
   --  switch, the EEFC is left set up with GPNVM bit 1 set, so that
   --  the board boots into SAM-BA; and, J-Link EDU doesn't reset SP
   --  (or PC, come to that; but it knows the start address).
   --
   --  Even then, you'd have to run the resulting image under GDB, I
   --  think, so not that much help in the long term
   procedure Program_Initialization
   with
     Export,
     Convention => Asm,
     External_Name => "program_initialization",
     No_Return;
   pragma Machine_Attribute (Program_Initialization, "naked");

   procedure Complete_Program_Initialization
   with
     No_Return;

   procedure Set_Up_Clock;
   procedure Set_Up_Clock is separate;

   --  Generated by gnatbind.
   procedure Main
   with
     Import,
     Convention => C,
     External_Name => "main";

   procedure Program_Initialization is
   begin
      --  _estack: the first address after the top of stack space
      System.Machine_Code.Asm ("ldr sp, =_estack", Volatile => True);
      Complete_Program_Initialization;
   end Program_Initialization;

   procedure Complete_Program_Initialization is
      --  The following symbols are set up in the linker script:
      --
      --  _sidata: the start of read/write data in Flash, to be copied
      --           to SRAM
      --  _sdata:  where read/write data is to be copied to
      --  _edata:  the first address after read/write data in SRAM
      --  _sbss:   the start of BSS (to be initialized to zero)
      --  _ebss:   the first address after BSS.

      use System.Storage_Elements;

      Sdata : Storage_Element
        with Import, Convention => Asm, External_Name => "_sdata";
      Edata : Storage_Element
        with Import, Convention => Asm, External_Name => "_edata";
      Sbss : Storage_Element
        with Import, Convention => Asm, External_Name => "_sbss";
      Ebss : Storage_Element
        with Import, Convention => Asm, External_Name => "_ebss";

      Data_Size : constant Storage_Offset := Edata'Address - Sdata'Address;

      --  Index from 1 so as to avoid subtracting 1 from the size
      Data_In_Flash : Storage_Array (1 .. Data_Size)
        with Import, Convention => Asm, External_Name => "_sidata";

      Data_In_Sram : Storage_Array (1 .. Data_Size)
        with Import, Convention => Asm, External_Name => "_sdata";

      Bss_Size : constant Storage_Offset := Ebss'Address - Sbss'Address;

      Bss : Storage_Array (1 .. Bss_Size)
        with Import, Convention => Ada, External_Name => "_sbss";

      VTOR : Interfaces.Unsigned_32
        with Import,
          Convention => Ada,
          Volatile,
          Address => System'To_Address (16#E000ED08#);
   begin
      Data_In_Sram := Data_In_Flash;
      Bss := (others => 0);

      VTOR := 16#00080000#;

      Set_Up_Clock;

      Main;

      --  Main shouldn't return, but just in case ..
      loop
         null;
      end loop;
   end Complete_Program_Initialization;

   -------------------------
   --  Interrupt vectors  --
   -------------------------

   --  Vector Table, 11057 23-Mar-15, Chapter 10.6.4

   procedure Dummy_Handler;
   procedure Dummy_Handler is
      IPSR : Interfaces.Unsigned_32
        with Volatile; -- don't want it to be optimised away
      use type Interfaces.Unsigned_32;
   begin
      System.Machine_Code.Asm
        ("mrs %0, ipsr",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", IPSR),
         Volatile => True);
      loop
         null;
      end loop;
   end Dummy_Handler;

   procedure HardFault_Handler;
   procedure HardFault_Handler is
   begin
      loop
         null;
      end loop;
   end HardFault_Handler;

   --  The remaining handlers are all defined as Weak so that they can
   --  be replaced by real handlers at link time.

   procedure SVC_Handler
   with Export, Convention => Ada, External_Name => "SVC_Handler";
   pragma Weak_External (SVC_Handler);
   procedure SVC_Handler is
   begin
      loop
         null;
      end loop;
   end SVC_Handler;

   procedure PendSV_Handler
   with Export, Convention => Ada, External_Name => "PendSV_Handler";
   pragma Weak_External (PendSV_Handler);
   procedure PendSV_Handler is
   begin
      loop
         null;
      end loop;
   end PendSV_Handler;

   procedure SysTick_Handler
   with Export, Convention => Ada, External_Name => "SysTick_Handler";
   pragma Weak_External (SysTick_Handler);
   procedure SysTick_Handler is
   begin
      loop
         null;
      end loop;
   end SysTick_Handler;

   --  The real IRQ_Handler , in System.Interrupts, uses ipsr to find
   --  which interrupt happened.
   procedure IRQ_Handler
   with Export, Convention => Ada, External_Name => "IRQ_Handler";
   pragma Weak_External (IRQ_Handler);
   procedure IRQ_Handler is
      IPSR : Interfaces.Unsigned_32
        with Volatile; -- don't want it to be optimised away
      use type Interfaces.Unsigned_32;
   begin
      System.Machine_Code.Asm
        ("mrs %0, ipsr",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", IPSR),
         Volatile => True);
      loop
         null;
      end loop;
   end IRQ_Handler;

   type Handler is access procedure;

   Vectors : array (-14 .. Ada.Interrupts.Names.CAN1_IRQ) of Handler :=
     (-9 .. -6 | -4 .. -3 => null,                      -- reserved
      -14                 => Dummy_Handler'Access,      -- NMI
      -13                 => HardFault_Handler'Access,  -- HardFault
      -12                 => Dummy_Handler'Access,      -- MemManagement
      -11                 => Dummy_Handler'Access,      -- BusFault
      -10                 => Dummy_Handler'Access,      -- UsageFault
      -5                  => SVC_Handler'Access,        -- SVCall
      -2                  => PendSV_Handler'Access,     -- PendSV
      -1                  => SysTick_Handler'Access,    -- SysTick
      0 .. Ada.Interrupts.Names.CAN1_IRQ =>
                             IRQ_Handler'Access)
     with
       Export,
       Convention         => Ada,
       External_Name      => "isr_vector";
   pragma Linker_Section (Vectors, ".isr_vector");

end Startup;
