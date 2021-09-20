/******************************************************************************
 *
 * Copyright(c) 2007 - 2017 Realtek Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of version 2 of the GNU General Public License as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 *****************************************************************************/

/* ************************************************************
 * include files
 * ************************************************************ */

#include "mp_precomp.h"

#include "../phydm_precomp.h"

#if (RTL8821A_SUPPORT == 1) || (RTL8881A_SUPPORT == 1)

s8 phydm_cck_rssi_8821a(struct dm_struct *dm, u16 lna_idx, u8 vga_idx)
{
	s8 rx_pwr_all = 0;

	switch (lna_idx) {
	case 5:
		rx_pwr_all = -38 - (2 * vga_idx);
		break;
	case 4:
		rx_pwr_all = -30 - (2 * vga_idx);
		break;
	case 2:
		rx_pwr_all = -17 - (2 * vga_idx);
		break;
	case 1:
		rx_pwr_all = -1 - (2 * vga_idx);
		break;
	case 0:
		rx_pwr_all = 15 - (2 * vga_idx);
		break;
	default:
		break;
	}

	return rx_pwr_all;
}

void phydm_set_ext_band_switch_8821A(void *dm_void, u32 band)
{
	struct dm_struct *dm = (struct dm_struct *)dm_void;

	/*Output Pin Settings*/
	odm_set_mac_reg(dm, R_0x4c, BIT(23), 0); /*select DPDT_P and DPDT_N as output pin*/
	odm_set_mac_reg(dm, R_0x4c, BIT(24), 1); /*by WLAN control*/

	odm_set_bb_reg(dm, R_0xcb4, 0xF, 7); /*DPDT_P = 1b'0*/
	odm_set_bb_reg(dm, R_0xcb4, 0xF0, 7); /*DPDT_N = 1b'0*/

	if (band == ODM_BAND_2_4G) {
		odm_set_bb_reg(dm, R_0xcb4, (BIT(29) | BIT(28)), 1);
		PHYDM_DBG(dm, DBG_ANT_DIV,
			  "***8821A set band switch = 2b'01\n");
	} else {
		odm_set_bb_reg(dm, R_0xcb4, BIT(29) | BIT(28), 2);
		PHYDM_DBG(dm, DBG_ANT_DIV,
			  "***8821A set band switch = 2b'10\n");
	}
}

void odm_dynamic_try_state_agg_8821a(struct dm_struct *dm)
{
	if ((dm->support_ic_type & ODM_RTL8821) && dm->support_interface == ODM_ITRF_USB) {
		if (dm->rssi_min > 25)
			odm_write_1byte(dm, 0x4CF, 0x02);
		else if (dm->rssi_min < 20)
			odm_write_1byte(dm, 0x4CF, 0x00);
	}
}

void odm_dynamic_packet_detection_th_8821a(struct dm_struct *dm)
{
	if (dm->support_ic_type & ODM_RTL8821) {
		if (dm->rssi_min <= 25) {
			/*odm_set_bb_reg(dm, REG_PWED_TH_JAGUAR, MASKDWORD, 0x2aaaf1a8);*/
			odm_set_bb_reg(dm, REG_PWED_TH_JAGUAR, 0x1ff0, 0x11a);
			odm_set_bb_reg(dm, REG_BW_INDICATION_JAGUAR, BIT(26), 1);
		} else if (dm->rssi_min >= 30) {
			/*odm_set_bb_reg(dm, REG_PWED_TH_JAGUAR, MASKDWORD, 0x2aaaeec8);*/
			odm_set_bb_reg(dm, REG_PWED_TH_JAGUAR, 0x1ff0, 0xec);
			odm_set_bb_reg(dm, REG_BW_INDICATION_JAGUAR, BIT(26), 0);
		}
	}
}

void odm_hw_setting_8821a(struct dm_struct *dm)
{
	odm_dynamic_try_state_agg_8821a(dm);
	odm_dynamic_packet_detection_th_8821a(dm);
}

#if (DM_ODM_SUPPORT_TYPE == ODM_WIN)
void odm_dynamic_tx_power_8821(void *dm_void, u8 *desc, u8 macid)
{
	struct dm_struct *dm = (struct dm_struct *)dm_void;
	struct cmn_sta_info *entry = NULL;
	u8 reg_c56 = 0;
	u8 txpwr_offset = 0;
	u8 rssi_tmp = 0;

	if (!is_sta_active(entry))
		return;

	PHYDM_DBG(dm, DBG_DYN_TXPWR, "[%s]======>\n", __func__);

	entry = dm->phydm_sta_info[macid];
	rssi_tmp = entry[macid].rssi_stat.rssi;

	if (rssi_tmp > 85) {
		reg_c56 = odm_read_1byte(dm, 0xc56);
		PHYDM_DBG(dm, DBG_DYN_TXPWR, "0xc56=0x%x\n", reg_c56);
		/* @Avoid TXAGC error after TX power offset is applied.
		For example: Reg0xc56=0x6, if txpwr_offset=3( reduce 11dB )
		Total power = 6-11= -5( overflow!! ), PA may be burned !
		so txpwr_offset should be adjusted by Reg0xc56*/

		if (reg_c56 < 14)
			txpwr_offset = 1;
		else if (reg_c56 < 22)
			txpwr_offset = 2;
		else
			txpwr_offset = 3;
	}

	SET_TX_DESC_TX_POWER_OFFSET_8812(desc, txpwr_offset);

	PHYDM_DBG(dm, DBG_DYN_TXPWR, "RSSI=%d, txpwr_ofst=%d\n",
		  rssi_tmp, txpwr_offset);
}
#endif /*@#if (DM_ODM_SUPPORT_TYPE == ODM_WIN)*/

#endif /* #if (RTL8821A_SUPPORT == 1) */
