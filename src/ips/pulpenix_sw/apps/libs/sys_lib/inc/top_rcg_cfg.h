/*
 * Filename 	: Sansa_SOC_Registers.h
 *
 * Created on   : Sun Feb 23 10:00:38 2020
 *
 */
#ifndef TOP_RCG_CFG_REGISTERS_H_
#define TOP_RCG_CFG_REGISTERS_H_

#define cyg_uint32 unsigned int

//=============================================================================
//  BLOCK TOP_RCG_CFG
//=============================================================================
#define   TOP_RCG_CFG_BASE_ADDR  0x1A300000


//=============================================================================
// top_rcg_cfg_reg00
#define TOP_RCG_CFG_TOP_RCG_CFG_REG00_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0000)
#define TOP_RCG_CFG_TOP_RCG_DIV0_RATIO_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0000)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg01
#define TOP_RCG_CFG_TOP_RCG_CFG_REG01_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0004)
#define TOP_RCG_CFG_TOP_RCG_DIV1_RATIO_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0004)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg02
#define TOP_RCG_CFG_TOP_RCG_CFG_REG02_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0008)
#define TOP_RCG_CFG_TOP_RCG_DIV2_RATIO_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0008)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg03
#define TOP_RCG_CFG_TOP_RCG_CFG_REG03_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x000C)
#define TOP_RCG_CFG_TOP_RCG_DIV3_RATIO_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x000C)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg04
#define TOP_RCG_CFG_TOP_RCG_CFG_REG04_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0080)
#define TOP_RCG_CFG_TOP_RCG_DIV_GO_SET_REG_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0080)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg05
#define TOP_RCG_CFG_TOP_RCG_CFG_REG05_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0084)
#define TOP_RCG_CFG_TOP_PLL_BYPASS_REG_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0084)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg06
#define TOP_RCG_CFG_TOP_RCG_CFG_REG06_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00A0)
#define TOP_RCG_CFG_TOP_RCG_CFG_BAD_RD_ADDR_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00A0)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg07
#define TOP_RCG_CFG_TOP_RCG_CFG_REG07_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00A4)
#define TOP_RCG_CFG_TOP_RCG_CFG_BAD_WR_ADDR_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00A4)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg08
#define TOP_RCG_CFG_TOP_RCG_CFG_REG08_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00A8)
#define TOP_RCG_CFG_TOP_RCG_CFG_IRQ_SIG_MASK_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00A8)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg09
#define TOP_RCG_CFG_TOP_RCG_CFG_REG09_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00AC)
#define TOP_RCG_CFG_TOP_RCG_CFG_IRQ_SIG_CLEAR_P_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00AC)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg0A
#define TOP_RCG_CFG_TOP_RCG_CFG_REG0A_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00B0)
#define TOP_RCG_CFG_TOP_RCG_CFG_IRQ_SIG_OUT_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00B0)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg0B
#define TOP_RCG_CFG_TOP_RCG_CFG_REG0B_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00B4)
#define TOP_RCG_CFG_TOP_RCG_CFG_IRQ_SIG_OUT_UNMSK_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00B4)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg0C
#define TOP_RCG_CFG_TOP_RCG_CFG_REG0C_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00C0)
#define TOP_RCG_CFG_TOP_DIV_CLK_ALIGN_VEC_MASK_N_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x00C0)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg0D
#define TOP_RCG_CFG_TOP_RCG_CFG_REG0D_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0100)
#define TOP_RCG_CFG_TOP_RCG_DIV0_RCC0_STATE_REG_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0100)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg0E
#define TOP_RCG_CFG_TOP_RCG_CFG_REG0E_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0140)
#define TOP_RCG_CFG_TOP_RCG_DIV1_RCC0_STATE_REG_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0140)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg0F
#define TOP_RCG_CFG_TOP_RCG_CFG_REG0F_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0180)
#define TOP_RCG_CFG_TOP_RCG_DIV2_RCC0_STATE_REG_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x0180)
//=============================================================================

//=============================================================================
// top_rcg_cfg_reg10
#define TOP_RCG_CFG_TOP_RCG_CFG_REG10_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x01C0)
#define TOP_RCG_CFG_TOP_RCG_DIV3_RCC0_STATE_REG_ADDR (TOP_RCG_CFG_BASE_ADDR + 0x01C0)
//=============================================================================



#endif /* TOP_RCG_CFG_REGISTERS_H_ */

