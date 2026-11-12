module("luci.controller.admin.telephony", package.seeall)

function index()
  entry({"admin", "telephony"}, firstchild(), "Telephony", 60).dependent=false
  entry({"admin", "telephony", "overview"}, template("admin_telephony/overview"), _("Overview"), 1)
  entry({"admin", "telephony", "sms"}, template("admin_telephony/sms"), _("SMS"), 2)
  entry({"admin", "telephony", "sms_list"}, call("action_sms_list")).leaf = true
  entry({"admin", "telephony", "sms_send"}, call("action_sms_send")).leaf = true
  entry({"admin", "telephony", "sms_action"}, call("action_sms_manage")).leaf = true
  entry({"admin", "telephony", "cellular"}, template("admin_telephony/cellular"), _("Cellular & Signal"), 3)
  entry({"admin", "telephony", "cellular_info"}, call("action_cellular_info")).leaf = true
  --entry({"admin", "telephony", "trigger_sim_unlock"}, template("admin_telephony/trigger_sim_unlock"), nil, nil)
  entry({"admin", "telephony", "trigger_sim_unlock"}, call("action_unlock_sim"), nil, nil)
  entry({"admin", "telephony", "trigger_change_nw_radio"}, template("admin_telephony/trigger_change_nw_radio"), nil, nil)
  entry({"admin", "telephony", "trigger_set_nw_rat_2g"}, template("admin_telephony/trigger_set_nw_rat_2g"), nil, nil)
  entry({"admin", "telephony", "trigger_set_nw_rat_3g"}, template("admin_telephony/trigger_set_nw_rat_3g"), nil, nil)
  entry({"admin", "telephony", "trigger_set_nw_rat_4g"}, template("admin_telephony/trigger_set_nw_rat_4g"), nil, nil)
  entry({"admin", "telephony", "trigger_set_nw_rat_5g"}, template("admin_telephony/trigger_set_nw_rat_5g"), nil, nil)
  entry({"admin", "telephony", "trigger_set_nw_rat_45g"}, template("admin_telephony/trigger_set_nw_rat_45g"), nil, nil)
  entry({"admin", "telephony", "trigger_set_nw_rat_345g"}, template("admin_telephony/trigger_set_nw_rat_345g"), nil, nil)
  entry({"admin", "telephony", "trigger_set_nw_rat"}, call("action_set_rat_mode"), nil, nil)
  entry({"admin", "telephony", "trigger_set_radio_on_with_ia"}, call("action_radio_on_with_ia_apn"), nil, nil)
  entry({"admin", "telephony", "trigger_set_radio_on"}, template("admin_telephony/trigger_set_radio_on"), nil, nil)
  entry({"admin", "telephony", "trigger_set_radio_off"}, template("admin_telephony/trigger_set_radio_off"), nil, nil)
  entry({"admin", "telephony", "trigger_set_ims_on_with_apn"}, call("action_ims_on_with_apn"), nil, nil)
  entry({"admin", "telephony", "trigger_set_ims_on"}, template("admin_telephony/trigger_set_ims_on"), nil, nil)
  entry({"admin", "telephony", "trigger_set_ims_off"}, template("admin_telephony/trigger_set_ims_off"), nil, nil)
  entry({"admin", "telephony", "trigger_call_get_call_status"}, template("admin_telephony/trigger_call_get_call_status"), nil, nil)
  --entry({"admin", "telephony", "trigger_call_dial_constant"}, template("admin_telephony/trigger_call_dial_constant"), nil, nil)
  entry({"admin", "telephony", "trigger_call_dial_constant"}, call("action_dial_call"), nil, nil)
  entry({"admin", "telephony", "trigger_call_detect_and_dial"}, template("admin_telephony/trigger_call_detect_and_dial"), nil, nil)
  entry({"admin", "telephony", "trigger_call_dtmf"}, template("admin_telephony/trigger_call_dtmf"), nil, nil)
  entry({"admin", "telephony", "trigger_call_accept_ringing"}, template("admin_telephony/trigger_call_accept_ringing"), nil, nil)
  entry({"admin", "telephony", "trigger_call_accept_waiting"}, template("admin_telephony/trigger_call_accept_waiting"), nil, nil)
  entry({"admin", "telephony", "trigger_call_swap"}, template("admin_telephony/trigger_call_swap"), nil, nil)
  entry({"admin", "telephony", "trigger_call_merge"}, template("admin_telephony/trigger_call_merge"), nil, nil)
  entry({"admin", "telephony", "trigger_call_play_tone"}, template("admin_telephony/trigger_call_play_tone"), nil, nil)
  entry({"admin", "telephony", "trigger_call_mute"}, template("admin_telephony/trigger_call_mute"), nil, nil)
  entry({"admin", "telephony", "trigger_call_unmute"}, template("admin_telephony/trigger_call_unmute"), nil, nil)
  entry({"admin", "telephony", "trigger_call_set_volume"}, call("action_set_volume"), nil, nil)
  entry({"admin", "telephony", "trigger_call_hangup_all"}, template("admin_telephony/trigger_call_hangup_all"), nil, nil)
  entry({"admin", "telephony", "trigger_call_hangup_foreground"}, template("admin_telephony/trigger_call_hangup_foreground"), nil, nil)
  entry({"admin", "telephony", "trigger_call_speech_on"}, template("admin_telephony/trigger_call_speech_on"), nil, nil)
  entry({"admin", "telephony", "trigger_call_speech_off"}, template("admin_telephony/trigger_call_speech_off"), nil, nil)
end

function action_unlock_sim()
	--load htm contect
	luci.template.render("admin_telephony/trigger_sim_unlock", {})
	--Read input SIM pin
	local pin = luci.http.formvalue("pin")
	if pin then
		if luci.http.formvalue("unlock") then
			local command = string.format("mipc_wan_cli --sim_verify_pin \"%s\"", pin)
			luci.sys.exec(command)
		end
	end
end

function action_set_rat_mode()
	--load htm contect
	luci.template.render("admin_telephony/trigger_set_nw_rat", {})
	--Read input SIM pin
	local ratMode = luci.http.formvalue("ratMode")
	if ratMode then
		if luci.http.formvalue("Set") then
			local command = string.format("mipc_wan_cli --nw_set_rat \"%s\"", ratMode)
			luci.sys.exec(command)
		end
	end
end

function action_radio_on_with_ia_apn()
	--load htm contect
	luci.template.render("admin_telephony/trigger_set_radio_on_with_ia", {})
	--Read ia apn
	local ia = luci.http.formvalue("ia")
	if ia then
		if luci.http.formvalue("ia_apn") then
			local command = string.format("mtk_ia \"%s\"", ia)
			luci.sys.exec(command)
		end
	end
end

function action_ims_on_with_apn()
	--load htm contect
	luci.template.render("admin_telephony/trigger_set_ims_on_with_apn", {})
	--Read ia apn
	local ims_apn = luci.http.formvalue("ims_apn")
	if ims_apn then
		if luci.http.formvalue("ims_cfg_on") then
			local command = string.format("mipc_wan_cli --apn_profile_set %s", ims_apn)
            luci.sys.exec(command)
            local command1 = string.format("mipc_wan_cli --nw_radio_state_set 0")
            luci.sys.exec(command1)
            local command2 = string.format("mipc_wan_cli --at_cmd AT+CIREG=2")
            luci.sys.exec(command2)
            local command3 = string.format("mipc_wan_cli --nw_radio_state_set 1")
            luci.sys.exec(command3)
            local command4 = string.format("mipc_wan_cli --ims_set_config 3")
            luci.sys.exec(command4)
		end
	end
end

function action_dial_call()
	--load htm contect
	luci.template.render("admin_telephony/trigger_call_dial_constant", {})
	--Read input number
	local dialNumber = luci.http.formvalue("dialNumber")
	if dialNumber then
		if luci.http.formvalue("Dial") then
			local command = string.format("mipc_wan_cli --dial_request=\"%s\"", dialNumber)
			luci.sys.exec(command)
		end
	end
end

function action_set_volume()
	--load htm contect
	luci.template.render("admin_telephony/trigger_call_set_volume", {})
	--Read input value
	local volume = luci.http.formvalue("volume")
	if volume then
		if luci.http.formvalue("set_volume") then
			local command = string.format("amixer -D mtk_phonecall cset numid=3 %s", volume)
			luci.sys.exec(command)
		end
	end
end

-- === SMS Management (added for LuCI Telephony -> SMS) ===
local SMS_INBOX_DIR = "/xdata/SMS/Inbox"
local SMS_NEW_FILE  = "/xdata/SMS/sms_new.txt"

local function write_json(status_code, payload)
	local http  = require "luci.http"
	local jsonc = require "luci.jsonc"
	if status_code then
		http.status(status_code, status_code == 400 and "Bad Request" or "OK")
	end
	http.prepare_content("application/json")
	http.write(jsonc.stringify(payload))
end

local function is_valid_sms_filename(name)
	return type(name) == "string" and name:match("^sms_[%w_]+%.txt$") ~= nil
end

local function sanitize_phone(raw)
	if type(raw) ~= "string" then
		return nil, "Phone number is required."
	end
	local clean = raw:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", "")
	if #clean == 0 or #clean > 32 then
		return nil, "Phone number must be 1 to 32 characters."
	end
	if not clean:match("^%+?[0-9%*#][0-9%*#%-]*$") then
		return nil, "Phone number contains invalid characters."
	end
	return clean
end

local function sanitize_sms_text(raw)
	if type(raw) ~= "string" then
		return nil, "Message text is required."
	end
	local clean = raw:gsub("\r\n", " "):gsub("[\r\n]", " "):gsub("^%s+", ""):gsub("%s+$", "")
	clean = clean:gsub('"', "'")
	if #clean == 0 then
		return nil, "Message cannot be empty."
	end
	if #clean > 160 then
		return nil, "Message exceeds 160 characters."
	end
	if clean:find("[%$`\\]") or clean:find("[%z\1-\31]") then
		return nil, "Message cannot contain $, `, \\, or control characters."
	end
	return clean
end

local function extract_sms_content(obj)
	if obj.PduContent ~= nil then
		return tostring(obj.PduContent)
	end
	local parts = {}
	for k, v in pairs(obj) do
		local idx = type(k) == "string" and k:match("^PduContent(%d+)$")
		if idx and v ~= nil then
			parts[#parts + 1] = { idx = tonumber(idx) or 0, text = tostring(v) }
		end
	end
	if #parts == 0 then return "" end
	table.sort(parts, function(a, b) return a.idx < b.idx end)
	local out = {}
	for _, p in ipairs(parts) do out[#out + 1] = p.text end
	return table.concat(out)
end

local function read_all_sms()
	local fs    = require "nixio.fs"
	local sys   = require "luci.sys"
	local jsonc = require "luci.jsonc"

	local new_st = fs.stat(SMS_NEW_FILE)
	if new_st and (new_st.size or 0) > 0 then
		sys.process.exec({"/usr/sbin/smscmd", "trans", SMS_NEW_FILE}, true, true)
	end

	local messages = {}
	local counts = { total = 0, inbox = 0, unread = 0, sent = 0, draft = 0 }
	local dir_iter = fs.dir(SMS_INBOX_DIR)
	if not dir_iter then
		return messages, counts
	end

	for fname in dir_iter do
		if is_valid_sms_filename(fname) then
			local raw = fs.readfile(SMS_INBOX_DIR .. "/" .. fname)
			local obj = raw and jsonc.parse(raw)
			if type(obj) == "table" then
				local state = tostring(obj.State or "")
				counts.total = counts.total + 1
				if state == "REC UNREAD" then
					counts.inbox = counts.inbox + 1
					counts.unread = counts.unread + 1
				elseif state == "REC READ" then
					counts.inbox = counts.inbox + 1
				elseif state == "STO SENT" then
					counts.sent = counts.sent + 1
				elseif state == "STO DRAFT" then
					counts.draft = counts.draft + 1
				end
				messages[#messages + 1] = {
					filename = fname,
					index = obj.Index or 0,
					state = state,
					from = tostring(obj.From or ""),
					timestamp = tostring(obj.TimeStamp or ""),
					content = extract_sms_content(obj)
				}
			end
		end
	end

	table.sort(messages, function(a, b)
		if a.timestamp ~= b.timestamp then
			return a.timestamp > b.timestamp
		end
		return a.filename > b.filename
	end)

	return messages, counts
end

local function query_modem_sms_info()
	local sys = require "luci.sys"
	local info = { cpms = "", csca = "" }

	local cpms_res = sys.process.exec({"/usr/bin/mipc_wan_cli", "--at_cmd", "AT+CPMS?"}, true, true)
	if cpms_res and cpms_res.stdout then
		local line = cpms_res.stdout:match("%+CPMS:%s*([^\r\n]+)")
		if line then info.cpms = line end
	end

	local csca_res = sys.process.exec({"/usr/bin/mipc_wan_cli", "--at_cmd", "AT+CSCA?"}, true, true)
	if csca_res and csca_res.stdout then
		local line = csca_res.stdout:match("%+CSCA:%s*([^\r\n]+)")
		if line then info.csca = line end
	end

	return info
end

function action_sms_list()
	local http = require "luci.http"
	local messages, counts = read_all_sms()
	local payload = {
		ok = true,
		counts = counts,
		messages = messages
	}
	if http.formvalue("modem_info") == "1" then
		payload.modem = query_modem_sms_info()
	end
	write_json(nil, payload)
end

function action_sms_send()
	if not luci.dispatcher.test_post_security() then
		return
	end
	local http = require "luci.http"
	local sys  = require "luci.sys"

	local mode = http.formvalue("mode") or "send"
	if mode ~= "send" and mode ~= "save" then
		write_json(400, { ok = false, error = "Invalid operation mode." })
		return
	end

	local phone, perr = sanitize_phone(http.formvalue("phone"))
	if not phone then
		write_json(400, { ok = false, error = perr })
		return
	end

	local msg, merr = sanitize_sms_text(http.formvalue("message"))
	if not msg then
		write_json(400, { ok = false, error = merr })
		return
	end

	local res = sys.process.exec({"/usr/sbin/smscmd", mode, phone, msg}, true, true)
	local ok = (res and res.code == 0)
	write_json(nil, {
		ok = ok,
		mode = mode,
		code = res and res.code or -1,
		output = (res and res.stdout) or "",
		error = (not ok) and ((res and res.stderr ~= "" and res.stderr) or "smscmd failed") or nil
	})
end

function action_sms_manage()
	if not luci.dispatcher.test_post_security() then
		return
	end
	local http = require "luci.http"
	local fs   = require "nixio.fs"
	local sys  = require "luci.sys"

	local op = http.formvalue("op")
	local filename = http.formvalue("filename")
	if not is_valid_sms_filename(filename) then
		write_json(400, { ok = false, error = "Invalid SMS filename." })
		return
	end

	local fullpath = SMS_INBOX_DIR .. "/" .. filename
	if not fs.stat(fullpath) then
		write_json(400, { ok = false, error = "SMS file not found." })
		return
	end

	local cmd_map = {
		mark_read   = {"/usr/sbin/smscmd", "update", filename, "REC READ"},
		mark_unread = {"/usr/sbin/smscmd", "update", filename, "REC UNREAD"},
		delete      = {"/usr/sbin/smscmd", "del", filename}
	}
	local argv = cmd_map[op]
	if not argv then
		write_json(400, { ok = false, error = "Unsupported SMS action." })
		return
	end

	local res = sys.process.exec(argv, true, true)
	local ok = (res and res.code == 0)
	write_json(nil, {
		ok = ok,
		op = op,
		filename = filename,
		output = (res and res.stdout) or "",
		error = (not ok) and ((res and res.stderr ~= "" and res.stderr) or "Action failed") or nil
	})
end

function action_cellular_info()
	local cell = require "luci.model.cellular"
	local data = cell.get_cellular_info()
	write_json(nil, data)
end
