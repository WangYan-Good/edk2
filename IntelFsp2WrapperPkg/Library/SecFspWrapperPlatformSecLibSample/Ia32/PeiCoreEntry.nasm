;------------------------------------------------------------------------------
;
; Copyright (c) 2016, Intel Corporation. All rights reserved.<BR>
; SPDX-License-Identifier: BSD-2-Clause-Patent
;
; Module Name:
;
;  PeiCoreEntry.nasm
;
; Abstract:
;
;   Find and call SecStartup
;
;------------------------------------------------------------------------------

SECTION .text

extern ASM_PFX(SecStartup)
extern ASM_PFX(PlatformInit)

; wangyan comments:
; ESP: External Stack Pointer, 32-bit 栈顶指针
; 栈的增长方向是向下的，即小地址 -> 大地址
; 其中，最大地址为栈底，最小地址为栈顶
; 栈的特性：先进后出
;
; 0xFFFF|-------------------|----> 栈底
;       |                   |
;       |      Stack        |
; 0x0000|-------------------|----> 栈顶
;
global ASM_PFX(CallPeiCoreEntryPoint)
ASM_PFX(CallPeiCoreEntryPoint):
  ;
  ; Obtain the hob list pointer
  ;
  ; wangyan comments:
  ; 将当前栈顶指针的地址往后偏移 4*32 位, 取到 HOB list 的指针地址
  ; 将 HOB list 指针地址送入 EAX 通用寄存器中
  ;
  ; 
  ; 0xFFFFFFFF|----------------------|----> [ESP + 0xC]
  ;           |                      |
  ;           |       Stack          |
  ;       X+4 | HOB list pointer Add |<------>
  ;           |                      | 4 Byte = 32 bit
  ;         X |                      |<----- ESP
  ;           ~                      ~
  ; 0x00000000|----------------------|----> [ESP + 8]
  ;
  mov     eax, [esp+4]
  ;
  ; Obtain the stack information
  ;   ECX: start of range
  ;   EDX: end of range
  ;
  mov     ecx, [esp+8]
  mov     edx, [esp+0xC]

  ;
  ; Platform init
  ;
  pushad
  push edx
  push ecx
  push eax
  call ASM_PFX(PlatformInit)
  pop  eax
  pop  eax
  pop  eax
  popad

  ;
  ; Set stack top pointer
  ;
  mov     esp, edx

  ;
  ; Push the hob list pointer
  ;
  push    eax

  ;
  ; Save the value
  ;   ECX: start of range
  ;   EDX: end of range
  ;
  mov     ebp, esp
  push    ecx
  push    edx

  ;
  ; Push processor count to stack first, then BIST status (AP then BSP)
  ;
  mov     eax, 1
  cpuid
  shr     ebx, 16
  and     ebx, 0xFF
  cmp     bl, 1
  jae     PushProcessorCount

  ;
  ; Some processors report 0 logical processors.  Effectively 0 = 1.
  ; So we fix up the processor count
  ;
  inc     ebx

PushProcessorCount:
  push    ebx

  ;
  ; We need to implement a long-term solution for BIST capture.  For now, we just copy BSP BIST
  ; for all processor threads
  ;
  xor     ecx, ecx
  mov     cl, bl
PushBist:
  movd    eax, mm0
  push    eax
  loop    PushBist

  ; Save Time-Stamp Counter
  movd eax, mm5
  push eax

  movd eax, mm6
  push eax

  ;
  ; Pass entry point of the PEI core
  ;
  mov     edi, 0xFFFFFFE0
  push    DWORD [edi]

  ;
  ; Pass BFV into the PEI Core
  ;
  mov     edi, 0xFFFFFFFC
  push    DWORD [edi]

  ;
  ; Pass stack size into the PEI Core
  ;
  mov     ecx, [ebp - 4]
  mov     edx, [ebp - 8]
  push    ecx       ; RamBase

  sub     edx, ecx
  push    edx       ; RamSize

  ;
  ; Pass Control into the PEI Core
  ;
  call ASM_PFX(SecStartup)

