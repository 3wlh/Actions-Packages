local name = "dnsto"
module("luci.controller."..name, package.seeall) 

function index()
	entry({"admin", "services", "name"}, firstchild(), _("DNDTO"), 90).dependent = true
	entry({"admin", "services",name.."_status"}, call("Run_status"))
	-- 注册菜单 
	entry({"admin", "services", name, "settings"}, cbi("dnsto/settings"), _("Settings"), 10).leaf = true
	entry({"admin", "services", name, "parse"}, template("dnsto/parse"), _("Parse"), 20).leaf = true
	entry({"admin", "services", name, "logs"}, template("dnsto/logs"), _("Logs"), 30).leaf = true
end

function Run_status()
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get("dnsto", "config", "port"))
	local token = uci:get("dnsto", "config", "token")
	local cmd = string.format("pgrep %s* >/dev/null", name)
	local status = {
		running = (luci.sys.call(cmd) == 0),
		port = (port or 5063),
		token = (token or "")
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end