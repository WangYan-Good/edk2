/** @file
  Sample to provide platform init function.

  Copyright (c) 2014 - 2016, Intel Corporation. All rights reserved.<BR>
  SPDX-License-Identifier: BSD-2-Clause-Patent

**/

#include <PiPei.h>
#include <Library/DebugLib.h>
#include <Library/SerialPortLib.h>

/**
  Platform initialization.

  @param[in] FspHobList   HobList produced by FSP.
  @param[in] StartOfRange Start of temporary RAM.
  @param[in] EndOfRange   End of temporary RAM.
**/
VOID
EFIAPI
PlatformInit (
  IN VOID  *FspHobList,      // [esp+4] -> EAX
  IN VOID  *StartOfRange,    // [esp+8] -> ECX
  IN VOID  *EndOfRange       // [esp+0xC] -> EDX
  )
{
  //
  // Platform initialization
  // Enable Serial port here
  //
  SerialPortInitialize ();

  //
  // wangyan comments - log instance:
  // FspHobList - 0x0
  // StartOfRange - 0xFE800000
  // EndOfRange - 0xFE9FFF00
  //
  DEBUG ((DEBUG_INFO, "PrintPeiCoreEntryPointParam in PlatformInit\n"));
  DEBUG ((DEBUG_INFO, "FspHobList - 0x%x\n", FspHobList));
  DEBUG ((DEBUG_INFO, "StartOfRange - 0x%x\n", StartOfRange));
  DEBUG ((DEBUG_INFO, "EndOfRange - 0x%x\n", EndOfRange));
}
