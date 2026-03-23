local name = "mddns"
module("luci.controller."..name, package.seeall) 

function index()
	entry({"admin", "services", name}, firstchild(), _("MultiDDNS"), 90).dependent = true
	entry({"admin", "services",name.."_status"}, call("Run_status"))
	-- 注册菜单 
	entry({"admin", "services", name, "settings"}, cbi(name.."/settings"), _("Settings"), 10).leaf = true
	entry({"admin", "services", name, "parse"}, template(name.."/parse"), _("Parse"), 20).leaf = true
	entry({"admin", "services", name, "logs"}, template(name.."/logs"), _("Logs"), 30).leaf = true
end

function Run_status()
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get(name, "config", "port"))
	local token = uci:get(name, "config", "token")
	local cmd = string.format("pgrep %s* >/dev/null", name)
	local status = {
		running = (luci.sys.call(cmd) == 0),
		port = (port or 5063),
		token = (token or "")
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end