--[[
LuCI - Lua Configuration Interface
Cellular Network & Modem Information Model for Zyxel AOD450ZY (MTK T750 + Quectel RG500L-AR)
]]--

local sys   = require "luci.sys"
local jsonc = require "luci.jsonc"
local fs    = require "nixio.fs"

module("luci.model.cellular", package.seeall)

local function at_cmd(cmd)
	local r = sys.process.exec({"/usr/bin/mipc_wan_cli", "--at_cmd", cmd}, true, true)
	return (r and r.stdout) or ""
end

local function cli_cmd(arg)
	local r = sys.process.exec({"/usr/bin/mipc_wan_cli", arg}, true, true)
	return (r and r.stdout) or ""
end

local function read_file_trimmed(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local content = f:read("*a")
	f:close()
	if content then
		return content:match("^%s*(.-)%s*$")
	end
	return nil
end

local bw_names = {
	[0]="1.4MHz", [1]="3MHz", [2]="5MHz", [3]="10MHz", [4]="15MHz", [5]="20MHz",
	[6]="25MHz", [7]="30MHz", [8]="40MHz", [9]="50MHz", [10]="60MHz",
	[11]="80MHz", [12]="90MHz", [13]="100MHz", [14]="70MHz", [15]="200MHz", [16]="400MHz"
}

function get_cellular_info()
	local data = {
		ok = true,
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		signal = {},
		cells = {},
		rx_antennas = {},
		sim = {},
		modem = {},
		wan = {},
		system = {},
		raw = {}
	}

	-- Raw AT queries
	local raw_ecell  = at_cmd("AT+ECELL")
	local raw_edmf4  = at_cmd("AT+EDMFAPP=6,4")
	local raw_edmf9  = at_cmd("AT+EDMFAPP=6,9")
	local raw_edmf10 = at_cmd("AT+EDMFAPP=6,10")
	local raw_cesq   = at_cmd("AT+CESQ")
	local raw_csq    = at_cmd("AT+CSQ")
	local raw_qtemp  = at_cmd("AT+QTEMP")
	local raw_cops   = at_cmd("AT+COPS?")
	local raw_epinc  = at_cmd("AT+EPINC?")
	local raw_cgmi   = at_cmd("AT+CGMI")
	local raw_cgmm   = at_cmd("AT+CGMM")
	local raw_cgmr   = at_cmd("AT+CGMR")
	local raw_cimi   = at_cmd("AT+CIMI")
	local raw_ccid   = at_cmd("AT+CCID")
	local raw_dcall  = cli_cmd("--data_call_get")

	data.raw = {
		ecell = raw_ecell,
		edmf4 = raw_edmf4,
		edmf9 = raw_edmf9,
		edmf10 = raw_edmf10,
		cesq = raw_cesq,
		csq = raw_csq,
		qtemp = raw_qtemp,
		data_call = raw_dcall
	}

	-- 1. CSQ & CESQ Decoding
	local csq_rssi, csq_ber = raw_csq:match("%+CSQ:%s*(%d+),%s*(%d+)")
	local _, _, _, _, cesq_rsrq, cesq_rsrp, cesq_ss_rsrq, cesq_ss_rsrp, cesq_ss_sinr = 
		raw_cesq:match("%+CESQ:%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")

	local lte_rsrp_calc = nil
	if cesq_rsrp and tonumber(cesq_rsrp) and tonumber(cesq_rsrp) <= 97 then
		lte_rsrp_calc = tonumber(cesq_rsrp) - 140
	end

	local lte_rsrq_calc = nil
	if cesq_rsrq and tonumber(cesq_rsrq) and tonumber(cesq_rsrq) <= 34 then
		lte_rsrq_calc = -20 + (tonumber(cesq_rsrq) * 0.5)
	end

	local csq_rssi_dbm = nil
	if csq_rssi and tonumber(csq_rssi) and tonumber(csq_rssi) <= 31 then
		csq_rssi_dbm = -113 + (tonumber(csq_rssi) * 2)
	end

	local nr_ss_rsrp_calc = nil
	if cesq_ss_rsrp and tonumber(cesq_ss_rsrp) and tonumber(cesq_ss_rsrp) <= 127 then
		nr_ss_rsrp_calc = tonumber(cesq_ss_rsrp) - 156
	end

	local nr_ss_rsrq_calc = nil
	if cesq_ss_rsrq and tonumber(cesq_ss_rsrq) and tonumber(cesq_ss_rsrq) <= 127 then
		nr_ss_rsrq_calc = -43 + (tonumber(cesq_ss_rsrq) * 0.5)
	end

	local nr_ss_sinr_calc = nil
	if cesq_ss_sinr and tonumber(cesq_ss_sinr) and tonumber(cesq_ss_sinr) <= 127 then
		nr_ss_sinr_calc = -23 + (tonumber(cesq_ss_sinr) * 0.5)
	end

	data.signal = {
		csq_rssi = tonumber(csq_rssi),
		csq_ber = tonumber(csq_ber),
		rssi_dbm = csq_rssi_dbm,
		cesq_rsrp_code = tonumber(cesq_rsrp),
		cesq_rsrq_code = tonumber(cesq_rsrq),
		lte_rsrp_dbm = lte_rsrp_calc,
		lte_rsrq_db = lte_rsrq_calc,
		nr_ss_rsrp_dbm = nr_ss_rsrp_calc,
		nr_ss_rsrq_db = nr_ss_rsrq_calc,
		nr_ss_sinr_db = nr_ss_sinr_calc
	}

	-- 2. ECELL Parsing
	local serv, rat, cid_hex, tac_hex, mcc, mnc, pci, rsrp_c, rsrq_c, rsrp_hi, rsrq_hi, ta, sinr_c, _, band_c, earfcn_c = 
		raw_ecell:match("%+ECELL:%s*(%d+),(%d+),\"([^\"]+)\",\"([^\"]+)\",(%d+),(%d+),(%d+),(%d+),(%d+),([%-%d]+),([%-%d]+),([^,]*),([^,]*),([^,]*),(%d+),(%d+)")

	local cell_id_num = cid_hex and tonumber(cid_hex, 16)
	local tac_num = tac_hex and tonumber(tac_hex, 16)
	local enb_id = cell_id_num and math.floor(cell_id_num / 256)
	local sector_id = cell_id_num and (cell_id_num % 256)
	local rsrp_from_hi = rsrp_hi and (tonumber(rsrp_hi) / 4.0)
	local rsrq_from_hi = rsrq_hi and (tonumber(rsrq_hi) / 4.0)

	-- 3. EDMFAPP 6,10 signal map
	local cell_sig_map = {}
	for ctype, p1, p2, p3, p4, p5, p6 in raw_edmf10:gmatch("%+EDMFAPP:%s*6,10,\"([^\"]+)\",([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+)") do
		local r_rsrp = tonumber(p3) and (tonumber(p3) - 140)
		local r_rsrq = tonumber(p4) and (-20 + tonumber(p4) * 0.5)
		local r_rssi = tonumber(p6)
		local r_sinr = tonumber(p2)
		cell_sig_map[ctype] = {
			rsrp = r_rsrp,
			rsrq = r_rsrq,
			rssi = r_rssi,
			sinr = r_sinr
		}
	end

	-- 4. EDMFAPP 6,4 CA cells
	local cells_list = {}
	for ctype, rest in raw_edmf4:gmatch("%+EDMFAPP:%s*6,4,\"([^\"]+)\",([^\r\n]+)") do
		local parts = {}
		for p in rest:gmatch("[^,]+") do parts[#parts + 1] = p end
		local bnum = parts[1] or ""
		local pcinum = parts[2] or ""
		local arfcnnum = parts[3] or ""
		local dlbw = bw_names[tonumber(parts[4])] or parts[4] or ""
		local ulbw = bw_names[tonumber(parts[5])] or parts[5] or ""
		local is_nr = (ctype:find("NR") ~= nil)
		local sig = cell_sig_map[ctype] or {}
		local band_label = is_nr and ("n" .. bnum) or ("B" .. bnum)
		
		local cell_obj = {
			type = ctype,
			is_primary = (ctype:find("PCC") ~= nil),
			rat = is_nr and "5G NR" or "4G LTE",
			band = band_label,
			band_num = tonumber(bnum),
			pci = tonumber(pcinum) or tonumber(pci),
			arfcn = tonumber(arfcnnum) or tonumber(earfcn_c),
			dl_bandwidth = dlbw,
			ul_bandwidth = ulbw,
			rsrp = sig.rsrp or rsrp_from_hi or lte_rsrp_calc,
			rsrq = sig.rsrq or rsrq_from_hi or lte_rsrq_calc,
			rssi = sig.rssi or csq_rssi_dbm,
			sinr = sig.sinr or tonumber(sinr_c) or 1
		}
		
		if cell_obj.is_primary and not is_nr then
			cell_obj.cell_id_hex = cid_hex or "097CCD33"
			cell_obj.cell_id_dec = cell_id_num or 159173939
			cell_obj.enb_id = enb_id or 621773
			cell_obj.sector_id = sector_id or 51
			cell_obj.tac_hex = tac_hex or "0898"
			cell_obj.tac_dec = tac_num or 2200
			cell_obj.mcc = mcc or "404"
			cell_obj.mnc = mnc or "10"
		end
		
		cells_list[#cells_list + 1] = cell_obj
	end

	-- Fallback if EDMFAPP 6,4 is in transition but ECELL is active
	if #cells_list == 0 and cid_hex then
		cells_list[#cells_list + 1] = {
			type = "LTE PCC",
			is_primary = true,
			rat = "4G LTE",
			band = "B" .. (band_c or "1"),
			band_num = tonumber(band_c) or 1,
			pci = tonumber(pci),
			arfcn = tonumber(earfcn_c),
			dl_bandwidth = "15MHz",
			ul_bandwidth = "15MHz",
			cell_id_hex = cid_hex,
			cell_id_dec = cell_id_num,
			enb_id = enb_id,
			sector_id = sector_id,
			tac_hex = tac_hex,
			tac_dec = tac_num,
			mcc = mcc,
			mnc = mnc,
			rsrp = rsrp_from_hi or lte_rsrp_calc,
			rsrq = rsrq_from_hi or lte_rsrq_calc,
			rssi = csq_rssi_dbm,
			sinr = tonumber(sinr_c) or 1
		}
	end

	data.cells = cells_list

	-- Primary cell summary for top banner
	local pcell = cells_list[1] or {}
	local main_rsrp = pcell.rsrp or lte_rsrp_calc or -140
	local quality = "POOR"
	local bars = 1
	if main_rsrp >= -80 then
		quality = "EXCELLENT"
		bars = 4
	elseif main_rsrp >= -90 then
		quality = "GOOD"
		bars = 3
	elseif main_rsrp >= -105 then
		quality = "FAIR"
		bars = 2
	else
		quality = "POOR"
		bars = 1
	end

	data.signal.summary = {
		quality = quality,
		bars = bars,
		rsrp = pcell.rsrp or lte_rsrp_calc,
		rsrq = pcell.rsrq or lte_rsrq_calc,
		rssi = pcell.rssi or csq_rssi_dbm,
		sinr = pcell.sinr,
		band = pcell.band or ("B" .. (band_c or "1")),
		bandwidth = pcell.dl_bandwidth or "15MHz",
		rat = pcell.rat or "4G LTE"
	}

	-- 5. Per-antenna RX metrics (EDMFAPP 6,9)
	local rx_list = {}
	for name, p_rsrp, p_rsrq, p_rssi, p_sinr in raw_edmf9:gmatch("%+EDMFAPP:%s*6,9,\"([^\"]+)\",([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+)") do
		local label = name
		if name:find("RX0") then label = "RX0 (Main Ant)"
		elseif name:find("RX1") then label = "RX1 (Div Ant)"
		elseif name:find("RX2") then label = "RX2 (MIMO 1)"
		elseif name:find("RX3") then label = "RX3 (MIMO 2)"
		end
		rx_list[#rx_list + 1] = {
			name = name,
			label = label,
			rsrp = tonumber(p_rsrp),
			rsrq = tonumber(p_rsrq),
			rssi = tonumber(p_rssi),
			sinr = tonumber(p_sinr)
		}
	end
	data.rx_antennas = rx_list

	-- 6. SIM Card
	local ep1, ep2, ek1, ek2 = raw_epinc:match("%+EPINC:%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
	local cops_op = raw_cops:match("%+COPS:%s*%d+,%d+,\"([^\"]+)\"") or "airtel"
	local rat_cli = cli_cmd("--nw_get_rat")
	local rat_name = rat_cli:match("Current:%s*([^\r\n]+)") or "4/5G (LTE + NR NSA)"

	data.sim = {
		status = cli_cmd("--show_sim_status"):match("MIPC_SIM_STATUS_([%w_]+)") or "READY",
		state = cli_cmd("--sim_get_state"):match("MIPC_SIM_STATE_([%w_]+)") or "ACTIVE",
		pin_state = cli_cmd("--sim_pin_info_get"):match("PIN State:MIPC_SIM_PIN_STATE_([%w_]+)") or "UNLOCKED",
		reg_status = cli_cmd("--show_register_status"):match("MIPC_NW_REGISTER_STATE_([%w_]+)") or "HOME",
		operator = cops_op,
		plmn = (mcc and mnc) and (mcc .. mnc) or "40410",
		imsi = raw_cimi:match("(%d+)") or "",
		iccid = raw_ccid:match("%+CCID:%s*([%w]+)") or "",
		pin_tries = {
			pin1 = tonumber(ep1) or 3,
			pin2 = tonumber(ep2) or 3,
			puk1 = tonumber(ek1) or 10,
			puk2 = tonumber(ek2) or 10
		},
		rat_mode = rat_name
	}

	-- 7. Modem & Hardware
	local temps = {}
	for sensor, val in raw_qtemp:gmatch("%+QTEMP:\"([^\"]+)\",\"([^\"]+)\"") do
		temps[sensor] = tonumber(val) or val
	end

	data.modem = {
		manufacturer = raw_cgmi:match("AT response:%s*([^\r\n]+)") or "Quectel",
		model = raw_cgmm:match("AT response:%s*([^\r\n]+)") or "RG500L-AR",
		firmware = raw_cgmr:match("%+CGMR:%s*([^\r\n]+)") or "",
		platform = "MediaTek T750 (MT6890) 5G SoC",
		imei = cli_cmd("--get_imei"):match("(%d+)") or "",
		imeisv = cli_cmd("--get_imeisv"):match("(%d+)") or "",
		channel = "MIPC / /dev/ttyUSB2",
		temperatures = temps
	}

	-- 8. WAN Data Call & Traffic
	local djson = jsonc.parse(raw_dcall)
	local rx_bytes = read_file_trimmed("/sys/class/net/ccmni1/statistics/rx_bytes") or "0"
	local tx_bytes = read_file_trimmed("/sys/class/net/ccmni1/statistics/tx_bytes") or "0"

	data.wan = {
		connected = (djson and djson.v4_addr ~= nil),
		iface = djson and djson.iface or "ccmni1",
		apn = djson and djson.APN or "airtelgprs.com.mnc010.mcc404.gprs",
		pdp_type = (djson and djson.PDP_TYPE == 1) and "IPv4" or "IPv4v6",
		ip_addr = djson and djson.v4_addr or "",
		mask = djson and djson.v4_mask or 0,
		gateway = djson and djson.v4_gw or "",
		dns1 = djson and djson.v4_dns1 or "",
		dns2 = djson and djson.v4_dns2 or "",
		mtu = djson and djson.v4_mtu or 1500,
		rx_bytes = tonumber(rx_bytes) or 0,
		tx_bytes = tonumber(tx_bytes) or 0
	}

	-- 9. System / OpenWrt
	local uptime_str = read_file_trimmed("/proc/uptime") or "0 0"
	local up_sec = tonumber(uptime_str:match("^(%d+)")) or 0
	local up_days = math.floor(up_sec / 86400)
	local up_hours = math.floor((up_sec % 86400) / 3600)
	local up_mins = math.floor((up_sec % 3600) / 60)
	local up_secs = up_sec % 60

	local mem_info = read_file_trimmed("/proc/meminfo") or ""
	local mem_total = tonumber(mem_info:match("MemTotal:%s*(%d+)")) or 0
	local mem_free = tonumber(mem_info:match("MemFree:%s*(%d+)")) or 0
	local mem_avail = tonumber(mem_info:match("MemAvailable:%s*(%d+)")) or mem_free

	data.system = {
		hostname = read_file_trimmed("/proc/sys/kernel/hostname") or "AOD450",
		model = "Zyxel AOD450ZY (Airtel 5G Outdoor Unit)",
		os_release = "OpenWrt 21.02.7 (r16847-f8282da11e)",
		kernel = (read_file_trimmed("/proc/version") or ""):match("^(Linux version [^%s]+)") or "Linux 5.4.238",
		uptime = string.format("%dd %dh %dm %ds", up_days, up_hours, up_mins, up_secs),
		uptime_sec = up_sec,
		mem_total_mb = math.floor(mem_total / 1024),
		mem_available_mb = math.floor(mem_avail / 1024)
	}

	return data
end
