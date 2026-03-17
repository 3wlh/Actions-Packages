local name = "napcatapi"
module("luci.controller."..name, package.seeall) 

function index()
	if not nixio.fs.access("/etc/config/napcatapi") then
		return
	end
	entry({"admin", "services", name}, firstchild(), _("NapCat Api"), 90).dependent = true
	entry({"admin", "services",name"_status"}, call("Run_status"))
	-- 注册菜单 
	entry({"admin", "services", name, "settings"}, cbi("napcatapi/napcatapi"), _("Settings"), 10).leaf = true
	entry({"admin", "services", name, "edit"}, template("napcatapi/edit"), _("Edit"), 20).leaf = true
	entry({"admin", "services", name, "napcat"}, template("napcatapi/napcat"), _("NapCat"), 30).leaf = true
	entry({"admin", "services", name, "logs"}, template("napcatapi/logs"), _("Logs"), 40).leaf = true
end

function Run_status()
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get(name, "config", "port"))
	local token = uci:get(name, "config", "token")
	local cmd = string.format("pgrep %s* >/dev/null", name)
	local status = {
		running = (luci.sys.call(cmd) == 0),
		port = (port or 5663),
		token = (token or "")
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end