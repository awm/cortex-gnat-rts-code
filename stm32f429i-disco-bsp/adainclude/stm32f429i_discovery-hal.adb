--  Copyright (C) 2016 Free Software Foundation, Inc.
--
--  This file is free software; you can redistribute it and/or modify
--  it under terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 3, or (at your
--  option) any later version. This file is distributed in the hope
--  that it will be useful, but WITHOUT ANY WARRANTY; without even the
--  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
--  PURPOSE.
--
--  As a special exception under Section 7 of GPL version 3, you are
--  granted additional permissions described in the GCC Runtime
--  Library Exception, version 3.1, as published by the Free Software
--  Foundation.
--
--  You should have received a copy of the GNU General Public License
--  and a copy of the GCC Runtime Library Exception along with this
--  program; see the files COPYING3 and COPYING.RUNTIME respectively.
--  If not, see <http://www.gnu.org/licenses/>.

with Interfaces;

package body STM32F429I_Discovery.HAL is

   procedure Wait (Milliseconds : Natural) is
      procedure HAL_Delay (Milliseconds : Interfaces.Unsigned_32) with
        Import,
        Convention => C,
        External_Name => "HAL_Delay";
   begin
      HAL_Delay (Interfaces.Unsigned_32 (Milliseconds));
   end Wait;

end STM32F429I_Discovery.HAL;
