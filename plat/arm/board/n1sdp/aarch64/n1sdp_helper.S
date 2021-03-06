/*
 * Copyright (c) 2018-2019, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <arch.h>
#include <asm_macros.S>
#include <neoverse_n1.h>
#include <cpu_macros.S>
#include <platform_def.h>

	.globl	plat_arm_calc_core_pos
	.globl	plat_reset_handler

	/* -----------------------------------------------------
	 * unsigned int plat_arm_calc_core_pos(u_register_t mpidr)
	 *
	 * Helper function to calculate the core position.
	 * ((ChipId * N1SDP_MAX_CLUSTERS_PER_CHIP + ClusterId) *
	 * N1SDP_MAX_CPUS_PER_CLUSTER * N1SDP_MAX_PE_PER_CPU) +
	 * (CPUId * N1SDP_MAX_PE_PER_CPU) + ThreadId
	 *
	 * which can be simplified as:
	 *
	 * (((ChipId * N1SDP_MAX_CLUSTERS_PER_CHIP + ClusterId) *
	 * N1SDP_MAX_CPUS_PER_CLUSTER + CPUId) * N1SDP_MAX_PE_PER_CPU) +
	 * ThreadId
	 * ------------------------------------------------------
	 */

func plat_arm_calc_core_pos
	mov	x4, x0

	/*
	 * The MT bit in MPIDR is always set for n1sdp and the
	 * affinity level 0 corresponds to thread affinity level.
	 */

	/* Extract individual affinity fields from MPIDR */
	ubfx	x0, x4, #MPIDR_AFF0_SHIFT, #MPIDR_AFFINITY_BITS
	ubfx	x1, x4, #MPIDR_AFF1_SHIFT, #MPIDR_AFFINITY_BITS
	ubfx	x2, x4, #MPIDR_AFF2_SHIFT, #MPIDR_AFFINITY_BITS
	ubfx	x3, x4, #MPIDR_AFF3_SHIFT, #MPIDR_AFFINITY_BITS

	/* Compute linear position */
	mov	x4, #N1SDP_MAX_CLUSTERS_PER_CHIP
	madd	x2, x3, x4, x2
	mov	x4, #N1SDP_MAX_CPUS_PER_CLUSTER
	madd	x1, x2, x4, x1
	mov	x4, #N1SDP_MAX_PE_PER_CPU
	madd	x0, x1, x4, x0
	ret
endfunc plat_arm_calc_core_pos

	/* -----------------------------------------------------
	 * void plat_reset_handler(void);
	 *
	 * Determine the CPU MIDR and disable power down bit for
	 * that CPU.
	 * -----------------------------------------------------
	 */

func plat_reset_handler
	jump_if_cpu_midr NEOVERSE_N1_MIDR, N1
	ret

	/* -----------------------------------------------------
	 * Disable CPU power down bit in power control register
	 * -----------------------------------------------------
	 */
N1:
	mrs	x0, NEOVERSE_N1_CPUPWRCTLR_EL1
	bic	x0, x0, #NEOVERSE_N1_CORE_PWRDN_EN_MASK
	msr	NEOVERSE_N1_CPUPWRCTLR_EL1, x0
	isb
	ret
endfunc plat_reset_handler
