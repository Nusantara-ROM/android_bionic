/*
 * Copyright (C) 2020 The Android Open Source Project
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <private/bionic_asm.h>
#include <private/bionic_asm_dwarf_exprs.h>

// In the signal trampoline frame, sp points to an rt_sigframe, which is:
//  - 128-byte siginfo_t
//  - ucontext_t:
//     - 8-byte long
//     - 8-byte pointer
//     - 24-byte stack_t
//     - 128-byte signal set
//     - 8 bytes of padding because sigcontext has 16-byte alignment
//     - mcontext_t/sigcontext

#define OFFSET_SP_TO_SIGCONTEXT (128 + 8 + 8 + 24 + 128 + 8) // 304

// Offsets from sigcontext to each register.
#define OFFSET_GPRS 8   // offset to "__u64 regs[31]" field
#define OFFSET_SP 256   // offset to "__u64 sp" field

// Non-standard DWARF constants for the arm64 registers.
#define DW_ARM64_X0_X30 0   // x0..x30 are DWARF regs 0..30
#define DW_ARM64_SP 31

#define INVOKE_ON_GPRS(f)                          \
   f(0)  f(1)  f(2)  f(3)  f(4)  f(5)  f(6)  f(7)  \
   f(8)  f(9)  f(10) f(11) f(12) f(13) f(14) f(15) \
   f(16) f(17) f(18) f(19) f(20) f(21) f(22) f(23) \
   f(24) f(25) f(26) f(27) f(28) f(29) f(30)

#define RESTORE_GPR(regno)                                                         \
   m_cfi_breg_offset (DW_ARM64_X0_X30 + (regno)),                                  \
                     DW_ARM64_SP,                                                  \
                     (OFFSET_SP_TO_SIGCONTEXT + OFFSET_GPRS + (regno) * 8);

  .text
  .cfi_startproc
  .cfi_signal_frame
  m_cfi_def_cfa_deref DW_ARM64_SP, (OFFSET_SP_TO_SIGCONTEXT + OFFSET_SP)
  INVOKE_ON_GPRS(RESTORE_GPR)
  nop   // see comment in libc/arch-x86_64/bionic/__restore_rt.S about this nop.
ENTRY_PRIVATE_NO_DWARF(__restore_rt)
  mov x8, __NR_rt_sigreturn
  svc #0x0
END(__restore_rt)
