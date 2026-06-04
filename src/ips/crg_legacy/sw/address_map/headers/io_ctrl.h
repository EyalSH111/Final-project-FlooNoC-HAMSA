/*
 * Filename 	: Negev_SOC_Registers.h
 *
 * Created on   : Tue Aug 27 23:39:42 2019
 *
 */
#ifndef IO_CTRL_REGISTERS_H_
#define IO_CTRL_REGISTERS_H_

#define cyg_uint32 unsigned int

//=============================================================================
//  BLOCK IO_CTRL
//=============================================================================
#define   IO_CTRL_BASE_ADDR  0x1FC03C00


//=============================================================================
// io_ctrl_reg000
#define IO_CTRL_IO_CTRL_REG000_ADDR (IO_CTRL_BASE_ADDR + 0x00000)
#define IO_CTRL_IO_CTRL_BAD_RD_ADDR_ADDR (IO_CTRL_BASE_ADDR + 0x00000)
//=============================================================================

//=============================================================================
// io_ctrl_reg001
#define IO_CTRL_IO_CTRL_REG001_ADDR (IO_CTRL_BASE_ADDR + 0x00004)
#define IO_CTRL_IO_CTRL_BAD_WR_ADDR_ADDR (IO_CTRL_BASE_ADDR + 0x00004)
//=============================================================================

//=============================================================================
// io_ctrl_reg002
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	rd_err_p_irq_sig : 1;
		cyg_uint32	wr_err_p_irq_sig : 1;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg002_union;
#define IO_CTRL_IO_CTRL_REG002_ADDR (IO_CTRL_BASE_ADDR + 0x00008)
#define IO_CTRL_IO_CTRL_IRQ_SIG_MASK_ADDR (IO_CTRL_BASE_ADDR + 0x00008)
//=============================================================================

//=============================================================================
// io_ctrl_reg003
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_irq_sig_clear_p : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg003_union;
#define IO_CTRL_IO_CTRL_REG003_ADDR (IO_CTRL_BASE_ADDR + 0x0000C)
#define IO_CTRL_IO_CTRL_IRQ_SIG_CLEAR_P_ADDR (IO_CTRL_BASE_ADDR + 0x0000C)
//=============================================================================

//=============================================================================
// io_ctrl_reg004
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_irq_sig_out : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg004_union;
#define IO_CTRL_IO_CTRL_REG004_ADDR (IO_CTRL_BASE_ADDR + 0x00010)
#define IO_CTRL_IO_CTRL_IRQ_SIG_OUT_ADDR (IO_CTRL_BASE_ADDR + 0x00010)
//=============================================================================

//=============================================================================
// io_ctrl_reg005
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_irq_sig_out_unmsk : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg005_union;
#define IO_CTRL_IO_CTRL_REG005_ADDR (IO_CTRL_BASE_ADDR + 0x00014)
#define IO_CTRL_IO_CTRL_IRQ_SIG_OUT_UNMSK_ADDR (IO_CTRL_BASE_ADDR + 0x00014)
//=============================================================================

//=============================================================================
// io_ctrl_reg006
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	west_retention_latch_en : 1;
		cyg_uint32	south_retention_latch_en : 1;
		cyg_uint32	east_retention_latch_en : 1;
		cyg_uint32	north_retention_latch_en : 1;
		cyg_uint32	reserve_4_31 : 28;
	}bits;
}io_ctrl_io_ctrl_reg006_union;
#define IO_CTRL_IO_CTRL_REG006_ADDR (IO_CTRL_BASE_ADDR + 0x00018)
#define IO_CTRL_IO_CTRL_RETENTION_LATCH_EN_ADDR (IO_CTRL_BASE_ADDR + 0x00018)
//=============================================================================

//=============================================================================
// io_ctrl_reg009
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	udef_gem_gxl_rgmii_rx_clk_pull_en : 1;
		cyg_uint32	udef_gem_gxl_rgmii_rx_clk_pull_dir : 1;
		cyg_uint32	reserve_2_-1 : -2;
		cyg_uint32	io_ctrl_gem_gxl_rgmii_rx_clk_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg009_union;
#define IO_CTRL_IO_CTRL_REG009_ADDR (IO_CTRL_BASE_ADDR + 0x00024)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_RX_CLK_ADDR (IO_CTRL_BASE_ADDR + 0x00024)
//=============================================================================

//=============================================================================
// io_ctrl_reg00A
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	udef_gem_gxl_rgmii_rxd0_pull_en : 1;
		cyg_uint32	udef_gem_gxl_rgmii_rxd0_pull_dir : 1;
		cyg_uint32	reserve_2_-1 : -2;
		cyg_uint32	udef_gem_gxl_rgmii_rxd0_drv_strength : 4;
		cyg_uint32	io_ctrl_gem_gxl_rgmii_rxd0_sel : 2;
		cyg_uint32	reserve_6_31 : 26;
	}bits;
}io_ctrl_io_ctrl_reg00A_union;
#define IO_CTRL_IO_CTRL_REG00A_ADDR (IO_CTRL_BASE_ADDR + 0x00028)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_RXD0_ADDR (IO_CTRL_BASE_ADDR + 0x00028)
//=============================================================================

//=============================================================================
// io_ctrl_reg00B
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_rxd1_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg00B_union;
#define IO_CTRL_IO_CTRL_REG00B_ADDR (IO_CTRL_BASE_ADDR + 0x0002C)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_RXD1_ADDR (IO_CTRL_BASE_ADDR + 0x0002C)
//=============================================================================

//=============================================================================
// io_ctrl_reg00C
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_rxd2_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg00C_union;
#define IO_CTRL_IO_CTRL_REG00C_ADDR (IO_CTRL_BASE_ADDR + 0x00030)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_RXD2_ADDR (IO_CTRL_BASE_ADDR + 0x00030)
//=============================================================================

//=============================================================================
// io_ctrl_reg00D
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_rxd3_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg00D_union;
#define IO_CTRL_IO_CTRL_REG00D_ADDR (IO_CTRL_BASE_ADDR + 0x00034)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_RXD3_ADDR (IO_CTRL_BASE_ADDR + 0x00034)
//=============================================================================

//=============================================================================
// io_ctrl_reg00E
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_rx_ctl_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg00E_union;
#define IO_CTRL_IO_CTRL_REG00E_ADDR (IO_CTRL_BASE_ADDR + 0x00038)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_RX_CTL_ADDR (IO_CTRL_BASE_ADDR + 0x00038)
//=============================================================================

//=============================================================================
// io_ctrl_reg00F
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_tx_clk_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg00F_union;
#define IO_CTRL_IO_CTRL_REG00F_ADDR (IO_CTRL_BASE_ADDR + 0x0003C)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_TX_CLK_ADDR (IO_CTRL_BASE_ADDR + 0x0003C)
//=============================================================================

//=============================================================================
// io_ctrl_reg010
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_txd0_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg010_union;
#define IO_CTRL_IO_CTRL_REG010_ADDR (IO_CTRL_BASE_ADDR + 0x00040)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_TXD0_ADDR (IO_CTRL_BASE_ADDR + 0x00040)
//=============================================================================

//=============================================================================
// io_ctrl_reg011
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_txd1_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg011_union;
#define IO_CTRL_IO_CTRL_REG011_ADDR (IO_CTRL_BASE_ADDR + 0x00044)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_TXD1_ADDR (IO_CTRL_BASE_ADDR + 0x00044)
//=============================================================================

//=============================================================================
// io_ctrl_reg012
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_txd2_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg012_union;
#define IO_CTRL_IO_CTRL_REG012_ADDR (IO_CTRL_BASE_ADDR + 0x00048)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_TXD2_ADDR (IO_CTRL_BASE_ADDR + 0x00048)
//=============================================================================

//=============================================================================
// io_ctrl_reg013
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_txd3_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg013_union;
#define IO_CTRL_IO_CTRL_REG013_ADDR (IO_CTRL_BASE_ADDR + 0x0004C)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_TXD3_ADDR (IO_CTRL_BASE_ADDR + 0x0004C)
//=============================================================================

//=============================================================================
// io_ctrl_reg014
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gem_gxl_rgmii_tx_ctl_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg014_union;
#define IO_CTRL_IO_CTRL_REG014_ADDR (IO_CTRL_BASE_ADDR + 0x00050)
#define IO_CTRL_IO_CTRL_GEM_GXL_RGMII_TX_CTL_ADDR (IO_CTRL_BASE_ADDR + 0x00050)
//=============================================================================

//=============================================================================
// io_ctrl_reg015
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio0_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg015_union;
#define IO_CTRL_IO_CTRL_REG015_ADDR (IO_CTRL_BASE_ADDR + 0x00054)
#define IO_CTRL_IO_CTRL_GPIO0_ADDR (IO_CTRL_BASE_ADDR + 0x00054)
//=============================================================================

//=============================================================================
// io_ctrl_reg016
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio1_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg016_union;
#define IO_CTRL_IO_CTRL_REG016_ADDR (IO_CTRL_BASE_ADDR + 0x00058)
#define IO_CTRL_IO_CTRL_GPIO1_ADDR (IO_CTRL_BASE_ADDR + 0x00058)
//=============================================================================

//=============================================================================
// io_ctrl_reg017
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio10_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg017_union;
#define IO_CTRL_IO_CTRL_REG017_ADDR (IO_CTRL_BASE_ADDR + 0x0005C)
#define IO_CTRL_IO_CTRL_GPIO10_ADDR (IO_CTRL_BASE_ADDR + 0x0005C)
//=============================================================================

//=============================================================================
// io_ctrl_reg018
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio11_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg018_union;
#define IO_CTRL_IO_CTRL_REG018_ADDR (IO_CTRL_BASE_ADDR + 0x00060)
#define IO_CTRL_IO_CTRL_GPIO11_ADDR (IO_CTRL_BASE_ADDR + 0x00060)
//=============================================================================

//=============================================================================
// io_ctrl_reg019
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio12_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg019_union;
#define IO_CTRL_IO_CTRL_REG019_ADDR (IO_CTRL_BASE_ADDR + 0x00064)
#define IO_CTRL_IO_CTRL_GPIO12_ADDR (IO_CTRL_BASE_ADDR + 0x00064)
//=============================================================================

//=============================================================================
// io_ctrl_reg01A
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio13_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg01A_union;
#define IO_CTRL_IO_CTRL_REG01A_ADDR (IO_CTRL_BASE_ADDR + 0x00068)
#define IO_CTRL_IO_CTRL_GPIO13_ADDR (IO_CTRL_BASE_ADDR + 0x00068)
//=============================================================================

//=============================================================================
// io_ctrl_reg01B
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio14_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg01B_union;
#define IO_CTRL_IO_CTRL_REG01B_ADDR (IO_CTRL_BASE_ADDR + 0x0006C)
#define IO_CTRL_IO_CTRL_GPIO14_ADDR (IO_CTRL_BASE_ADDR + 0x0006C)
//=============================================================================

//=============================================================================
// io_ctrl_reg01C
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio15_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg01C_union;
#define IO_CTRL_IO_CTRL_REG01C_ADDR (IO_CTRL_BASE_ADDR + 0x00070)
#define IO_CTRL_IO_CTRL_GPIO15_ADDR (IO_CTRL_BASE_ADDR + 0x00070)
//=============================================================================

//=============================================================================
// io_ctrl_reg01D
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio16_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg01D_union;
#define IO_CTRL_IO_CTRL_REG01D_ADDR (IO_CTRL_BASE_ADDR + 0x00074)
#define IO_CTRL_IO_CTRL_GPIO16_ADDR (IO_CTRL_BASE_ADDR + 0x00074)
//=============================================================================

//=============================================================================
// io_ctrl_reg01E
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio17_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg01E_union;
#define IO_CTRL_IO_CTRL_REG01E_ADDR (IO_CTRL_BASE_ADDR + 0x00078)
#define IO_CTRL_IO_CTRL_GPIO17_ADDR (IO_CTRL_BASE_ADDR + 0x00078)
//=============================================================================

//=============================================================================
// io_ctrl_reg01F
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio18_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg01F_union;
#define IO_CTRL_IO_CTRL_REG01F_ADDR (IO_CTRL_BASE_ADDR + 0x0007C)
#define IO_CTRL_IO_CTRL_GPIO18_ADDR (IO_CTRL_BASE_ADDR + 0x0007C)
//=============================================================================

//=============================================================================
// io_ctrl_reg020
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio19_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg020_union;
#define IO_CTRL_IO_CTRL_REG020_ADDR (IO_CTRL_BASE_ADDR + 0x00080)
#define IO_CTRL_IO_CTRL_GPIO19_ADDR (IO_CTRL_BASE_ADDR + 0x00080)
//=============================================================================

//=============================================================================
// io_ctrl_reg021
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio2_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg021_union;
#define IO_CTRL_IO_CTRL_REG021_ADDR (IO_CTRL_BASE_ADDR + 0x00084)
#define IO_CTRL_IO_CTRL_GPIO2_ADDR (IO_CTRL_BASE_ADDR + 0x00084)
//=============================================================================

//=============================================================================
// io_ctrl_reg022
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio20_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg022_union;
#define IO_CTRL_IO_CTRL_REG022_ADDR (IO_CTRL_BASE_ADDR + 0x00088)
#define IO_CTRL_IO_CTRL_GPIO20_ADDR (IO_CTRL_BASE_ADDR + 0x00088)
//=============================================================================

//=============================================================================
// io_ctrl_reg023
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio21_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg023_union;
#define IO_CTRL_IO_CTRL_REG023_ADDR (IO_CTRL_BASE_ADDR + 0x0008C)
#define IO_CTRL_IO_CTRL_GPIO21_ADDR (IO_CTRL_BASE_ADDR + 0x0008C)
//=============================================================================

//=============================================================================
// io_ctrl_reg024
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio22_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg024_union;
#define IO_CTRL_IO_CTRL_REG024_ADDR (IO_CTRL_BASE_ADDR + 0x00090)
#define IO_CTRL_IO_CTRL_GPIO22_ADDR (IO_CTRL_BASE_ADDR + 0x00090)
//=============================================================================

//=============================================================================
// io_ctrl_reg025
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio23_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg025_union;
#define IO_CTRL_IO_CTRL_REG025_ADDR (IO_CTRL_BASE_ADDR + 0x00094)
#define IO_CTRL_IO_CTRL_GPIO23_ADDR (IO_CTRL_BASE_ADDR + 0x00094)
//=============================================================================

//=============================================================================
// io_ctrl_reg026
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio24_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg026_union;
#define IO_CTRL_IO_CTRL_REG026_ADDR (IO_CTRL_BASE_ADDR + 0x00098)
#define IO_CTRL_IO_CTRL_GPIO24_ADDR (IO_CTRL_BASE_ADDR + 0x00098)
//=============================================================================

//=============================================================================
// io_ctrl_reg027
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio25_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg027_union;
#define IO_CTRL_IO_CTRL_REG027_ADDR (IO_CTRL_BASE_ADDR + 0x0009C)
#define IO_CTRL_IO_CTRL_GPIO25_ADDR (IO_CTRL_BASE_ADDR + 0x0009C)
//=============================================================================

//=============================================================================
// io_ctrl_reg028
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio26_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg028_union;
#define IO_CTRL_IO_CTRL_REG028_ADDR (IO_CTRL_BASE_ADDR + 0x000A0)
#define IO_CTRL_IO_CTRL_GPIO26_ADDR (IO_CTRL_BASE_ADDR + 0x000A0)
//=============================================================================

//=============================================================================
// io_ctrl_reg029
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio27_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg029_union;
#define IO_CTRL_IO_CTRL_REG029_ADDR (IO_CTRL_BASE_ADDR + 0x000A4)
#define IO_CTRL_IO_CTRL_GPIO27_ADDR (IO_CTRL_BASE_ADDR + 0x000A4)
//=============================================================================

//=============================================================================
// io_ctrl_reg02A
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio28_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg02A_union;
#define IO_CTRL_IO_CTRL_REG02A_ADDR (IO_CTRL_BASE_ADDR + 0x000A8)
#define IO_CTRL_IO_CTRL_GPIO28_ADDR (IO_CTRL_BASE_ADDR + 0x000A8)
//=============================================================================

//=============================================================================
// io_ctrl_reg02B
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio29_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg02B_union;
#define IO_CTRL_IO_CTRL_REG02B_ADDR (IO_CTRL_BASE_ADDR + 0x000AC)
#define IO_CTRL_IO_CTRL_GPIO29_ADDR (IO_CTRL_BASE_ADDR + 0x000AC)
//=============================================================================

//=============================================================================
// io_ctrl_reg02C
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio3_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg02C_union;
#define IO_CTRL_IO_CTRL_REG02C_ADDR (IO_CTRL_BASE_ADDR + 0x000B0)
#define IO_CTRL_IO_CTRL_GPIO3_ADDR (IO_CTRL_BASE_ADDR + 0x000B0)
//=============================================================================

//=============================================================================
// io_ctrl_reg02D
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio30_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg02D_union;
#define IO_CTRL_IO_CTRL_REG02D_ADDR (IO_CTRL_BASE_ADDR + 0x000B4)
#define IO_CTRL_IO_CTRL_GPIO30_ADDR (IO_CTRL_BASE_ADDR + 0x000B4)
//=============================================================================

//=============================================================================
// io_ctrl_reg02E
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio31_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg02E_union;
#define IO_CTRL_IO_CTRL_REG02E_ADDR (IO_CTRL_BASE_ADDR + 0x000B8)
#define IO_CTRL_IO_CTRL_GPIO31_ADDR (IO_CTRL_BASE_ADDR + 0x000B8)
//=============================================================================

//=============================================================================
// io_ctrl_reg02F
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio4_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg02F_union;
#define IO_CTRL_IO_CTRL_REG02F_ADDR (IO_CTRL_BASE_ADDR + 0x000BC)
#define IO_CTRL_IO_CTRL_GPIO4_ADDR (IO_CTRL_BASE_ADDR + 0x000BC)
//=============================================================================

//=============================================================================
// io_ctrl_reg030
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio5_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg030_union;
#define IO_CTRL_IO_CTRL_REG030_ADDR (IO_CTRL_BASE_ADDR + 0x000C0)
#define IO_CTRL_IO_CTRL_GPIO5_ADDR (IO_CTRL_BASE_ADDR + 0x000C0)
//=============================================================================

//=============================================================================
// io_ctrl_reg031
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio6_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg031_union;
#define IO_CTRL_IO_CTRL_REG031_ADDR (IO_CTRL_BASE_ADDR + 0x000C4)
#define IO_CTRL_IO_CTRL_GPIO6_ADDR (IO_CTRL_BASE_ADDR + 0x000C4)
//=============================================================================

//=============================================================================
// io_ctrl_reg032
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio7_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg032_union;
#define IO_CTRL_IO_CTRL_REG032_ADDR (IO_CTRL_BASE_ADDR + 0x000C8)
#define IO_CTRL_IO_CTRL_GPIO7_ADDR (IO_CTRL_BASE_ADDR + 0x000C8)
//=============================================================================

//=============================================================================
// io_ctrl_reg033
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio8_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg033_union;
#define IO_CTRL_IO_CTRL_REG033_ADDR (IO_CTRL_BASE_ADDR + 0x000CC)
#define IO_CTRL_IO_CTRL_GPIO8_ADDR (IO_CTRL_BASE_ADDR + 0x000CC)
//=============================================================================

//=============================================================================
// io_ctrl_reg034
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_gpio9_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg034_union;
#define IO_CTRL_IO_CTRL_REG034_ADDR (IO_CTRL_BASE_ADDR + 0x000D0)
#define IO_CTRL_IO_CTRL_GPIO9_ADDR (IO_CTRL_BASE_ADDR + 0x000D0)
//=============================================================================

//=============================================================================
// io_ctrl_reg03A
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi0_cs0_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg03A_union;
#define IO_CTRL_IO_CTRL_REG03A_ADDR (IO_CTRL_BASE_ADDR + 0x000E8)
#define IO_CTRL_IO_CTRL_MMSPI0_CS0_ADDR (IO_CTRL_BASE_ADDR + 0x000E8)
//=============================================================================

//=============================================================================
// io_ctrl_reg03B
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi0_cs1_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg03B_union;
#define IO_CTRL_IO_CTRL_REG03B_ADDR (IO_CTRL_BASE_ADDR + 0x000EC)
#define IO_CTRL_IO_CTRL_MMSPI0_CS1_ADDR (IO_CTRL_BASE_ADDR + 0x000EC)
//=============================================================================

//=============================================================================
// io_ctrl_reg03C
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi0_cs2_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg03C_union;
#define IO_CTRL_IO_CTRL_REG03C_ADDR (IO_CTRL_BASE_ADDR + 0x000F0)
#define IO_CTRL_IO_CTRL_MMSPI0_CS2_ADDR (IO_CTRL_BASE_ADDR + 0x000F0)
//=============================================================================

//=============================================================================
// io_ctrl_reg03D
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi0_cs3_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg03D_union;
#define IO_CTRL_IO_CTRL_REG03D_ADDR (IO_CTRL_BASE_ADDR + 0x000F4)
#define IO_CTRL_IO_CTRL_MMSPI0_CS3_ADDR (IO_CTRL_BASE_ADDR + 0x000F4)
//=============================================================================

//=============================================================================
// io_ctrl_reg03E
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	udef_mmspi0_dclk_force_ie : 1;
		cyg_uint32	reserve_1_-1 : -1;
		cyg_uint32	io_ctrl_mmspi0_dclk_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg03E_union;
#define IO_CTRL_IO_CTRL_REG03E_ADDR (IO_CTRL_BASE_ADDR + 0x000F8)
#define IO_CTRL_IO_CTRL_MMSPI0_DCLK_ADDR (IO_CTRL_BASE_ADDR + 0x000F8)
//=============================================================================

//=============================================================================
// io_ctrl_reg03F
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi0_din_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg03F_union;
#define IO_CTRL_IO_CTRL_REG03F_ADDR (IO_CTRL_BASE_ADDR + 0x000FC)
#define IO_CTRL_IO_CTRL_MMSPI0_DIN_ADDR (IO_CTRL_BASE_ADDR + 0x000FC)
//=============================================================================

//=============================================================================
// io_ctrl_reg040
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi0_dout_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg040_union;
#define IO_CTRL_IO_CTRL_REG040_ADDR (IO_CTRL_BASE_ADDR + 0x00100)
#define IO_CTRL_IO_CTRL_MMSPI0_DOUT_ADDR (IO_CTRL_BASE_ADDR + 0x00100)
//=============================================================================

//=============================================================================
// io_ctrl_reg041
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi1_dclk_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg041_union;
#define IO_CTRL_IO_CTRL_REG041_ADDR (IO_CTRL_BASE_ADDR + 0x00104)
#define IO_CTRL_IO_CTRL_MMSPI1_DCLK_ADDR (IO_CTRL_BASE_ADDR + 0x00104)
//=============================================================================

//=============================================================================
// io_ctrl_reg042
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi1_din_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg042_union;
#define IO_CTRL_IO_CTRL_REG042_ADDR (IO_CTRL_BASE_ADDR + 0x00108)
#define IO_CTRL_IO_CTRL_MMSPI1_DIN_ADDR (IO_CTRL_BASE_ADDR + 0x00108)
//=============================================================================

//=============================================================================
// io_ctrl_reg043
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi1_dout_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg043_union;
#define IO_CTRL_IO_CTRL_REG043_ADDR (IO_CTRL_BASE_ADDR + 0x0010C)
#define IO_CTRL_IO_CTRL_MMSPI1_DOUT_ADDR (IO_CTRL_BASE_ADDR + 0x0010C)
//=============================================================================

//=============================================================================
// io_ctrl_reg044
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi2_dclk_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg044_union;
#define IO_CTRL_IO_CTRL_REG044_ADDR (IO_CTRL_BASE_ADDR + 0x00110)
#define IO_CTRL_IO_CTRL_MMSPI2_DCLK_ADDR (IO_CTRL_BASE_ADDR + 0x00110)
//=============================================================================

//=============================================================================
// io_ctrl_reg045
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi2_din_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg045_union;
#define IO_CTRL_IO_CTRL_REG045_ADDR (IO_CTRL_BASE_ADDR + 0x00114)
#define IO_CTRL_IO_CTRL_MMSPI2_DIN_ADDR (IO_CTRL_BASE_ADDR + 0x00114)
//=============================================================================

//=============================================================================
// io_ctrl_reg046
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mmspi2_dout_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg046_union;
#define IO_CTRL_IO_CTRL_REG046_ADDR (IO_CTRL_BASE_ADDR + 0x00118)
#define IO_CTRL_IO_CTRL_MMSPI2_DOUT_ADDR (IO_CTRL_BASE_ADDR + 0x00118)
//=============================================================================

//=============================================================================
// io_ctrl_reg047
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_spi_sif_cs_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg047_union;
#define IO_CTRL_IO_CTRL_REG047_ADDR (IO_CTRL_BASE_ADDR + 0x0011C)
#define IO_CTRL_IO_CTRL_SPI_SIF_CS_ADDR (IO_CTRL_BASE_ADDR + 0x0011C)
//=============================================================================

//=============================================================================
// io_ctrl_reg048
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_spi_sif_dclk_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg048_union;
#define IO_CTRL_IO_CTRL_REG048_ADDR (IO_CTRL_BASE_ADDR + 0x00120)
#define IO_CTRL_IO_CTRL_SPI_SIF_DCLK_ADDR (IO_CTRL_BASE_ADDR + 0x00120)
//=============================================================================

//=============================================================================
// io_ctrl_reg049
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_spi_sif_din_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg049_union;
#define IO_CTRL_IO_CTRL_REG049_ADDR (IO_CTRL_BASE_ADDR + 0x00124)
#define IO_CTRL_IO_CTRL_SPI_SIF_DIN_ADDR (IO_CTRL_BASE_ADDR + 0x00124)
//=============================================================================

//=============================================================================
// io_ctrl_reg04A
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_spi_sif_dout_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg04A_union;
#define IO_CTRL_IO_CTRL_REG04A_ADDR (IO_CTRL_BASE_ADDR + 0x00128)
#define IO_CTRL_IO_CTRL_SPI_SIF_DOUT_ADDR (IO_CTRL_BASE_ADDR + 0x00128)
//=============================================================================

//=============================================================================
// io_ctrl_reg04D
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_uart_rxd_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg04D_union;
#define IO_CTRL_IO_CTRL_REG04D_ADDR (IO_CTRL_BASE_ADDR + 0x00134)
#define IO_CTRL_IO_CTRL_UART_RXD_ADDR (IO_CTRL_BASE_ADDR + 0x00134)
//=============================================================================

//=============================================================================
// io_ctrl_reg04E
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_uart_txd_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg04E_union;
#define IO_CTRL_IO_CTRL_REG04E_ADDR (IO_CTRL_BASE_ADDR + 0x00138)
#define IO_CTRL_IO_CTRL_UART_TXD_ADDR (IO_CTRL_BASE_ADDR + 0x00138)
//=============================================================================

//=============================================================================
// io_ctrl_reg04F
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_iic_clk_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg04F_union;
#define IO_CTRL_IO_CTRL_REG04F_ADDR (IO_CTRL_BASE_ADDR + 0x0013C)
#define IO_CTRL_IO_CTRL_IIC_CLK_ADDR (IO_CTRL_BASE_ADDR + 0x0013C)
//=============================================================================

//=============================================================================
// io_ctrl_reg050
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_iic_data_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg050_union;
#define IO_CTRL_IO_CTRL_REG050_ADDR (IO_CTRL_BASE_ADDR + 0x00140)
#define IO_CTRL_IO_CTRL_IIC_DATA_ADDR (IO_CTRL_BASE_ADDR + 0x00140)
//=============================================================================

//=============================================================================
// io_ctrl_reg051
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mdc0_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg051_union;
#define IO_CTRL_IO_CTRL_REG051_ADDR (IO_CTRL_BASE_ADDR + 0x00144)
#define IO_CTRL_IO_CTRL_MDC0_ADDR (IO_CTRL_BASE_ADDR + 0x00144)
//=============================================================================

//=============================================================================
// io_ctrl_reg052
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_mdio0_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg052_union;
#define IO_CTRL_IO_CTRL_REG052_ADDR (IO_CTRL_BASE_ADDR + 0x00148)
#define IO_CTRL_IO_CTRL_MDIO0_ADDR (IO_CTRL_BASE_ADDR + 0x00148)
//=============================================================================

//=============================================================================
// io_ctrl_reg053
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_pwm0_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg053_union;
#define IO_CTRL_IO_CTRL_REG053_ADDR (IO_CTRL_BASE_ADDR + 0x0014C)
#define IO_CTRL_IO_CTRL_PWM0_ADDR (IO_CTRL_BASE_ADDR + 0x0014C)
//=============================================================================

//=============================================================================
// io_ctrl_reg054
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_pwm1_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg054_union;
#define IO_CTRL_IO_CTRL_REG054_ADDR (IO_CTRL_BASE_ADDR + 0x00150)
#define IO_CTRL_IO_CTRL_PWM1_ADDR (IO_CTRL_BASE_ADDR + 0x00150)
//=============================================================================

//=============================================================================
// io_ctrl_reg055
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_pwm2_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg055_union;
#define IO_CTRL_IO_CTRL_REG055_ADDR (IO_CTRL_BASE_ADDR + 0x00154)
#define IO_CTRL_IO_CTRL_PWM2_ADDR (IO_CTRL_BASE_ADDR + 0x00154)
//=============================================================================

//=============================================================================
// io_ctrl_reg056
typedef union {
	cyg_uint32 value;
	struct {
		cyg_uint32	io_ctrl_pwm3_sel : 2;
		cyg_uint32	reserve_2_31 : 30;
	}bits;
}io_ctrl_io_ctrl_reg056_union;
#define IO_CTRL_IO_CTRL_REG056_ADDR (IO_CTRL_BASE_ADDR + 0x00158)
#define IO_CTRL_IO_CTRL_PWM3_ADDR (IO_CTRL_BASE_ADDR + 0x00158)
//=============================================================================



#endif /* IO_CTRL_REGISTERS_H_ */
