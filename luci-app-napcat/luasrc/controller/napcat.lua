local name = "napcat"
module("luci.controller." .. name, package.seeall) 

function index() 
    entry({"admin", "services", name}, firstchild(), _("NapCat"), 90).dependent = true 
    entry({"admin", "services", name, "app"}, call("app"), _("Settings"), 10).leaf = true 
end 

-- 输出错误日志
local errors = {}
function log_error(msg)
    local safe_msg = msg:gsub("'", "'\\''")
    table.insert(errors, safe_msg)
    local cmd = string.format("logger -t %s 'napcat error: %s'",name ,safe_msg )
    os.execute(cmd)
end

function get_port() 
    math.randomseed(os.time()) 
    for _ = 1, 10 do 
        local port = math.random(1024, 65535) 
        local cmd = string.format("netstat -tunl | grep -qw :%d", port) 
        local ret = os.execute(cmd) 
        if ret ~= 0 then 
            return port
        end 
    end
    log_error("未获取可用到[Port]")
end 
 
function sess_token() 
    local http = require "luci.http"
    local ubus = require "ubus"
    local sid = http.getcookie("sysauth") or
                http.getcookie("sysauth_http") or
                http.getcookie("sysauth_https") or
                http.getcookie("sid")
    if not sid then
        log_error("未获取到会话[ID]") 
        return
    end
    local conn = ubus.connect() 
    if not conn then 
        return nil 
    end 
    local session_data = conn:call("session", "get", { ubus_rpc_session = sid }) 
    conn:close() 
    if session_data and session_data.values and session_data.values.token then 
        return session_data.values.token
    elseif session_data and session_data.token then
        return session_data.token
    end
    log_error("未获取到[token]")
    return nil
end 

function get_data()
    return get_port(), sess_token()
end

function app()
    local port, token = get_data()  
    local docker = "/usr/share/napcat/docker.json"
    if #errors > 0 then
        luci.template.render(name.."/errlog", { errors = errors })
        return
    end
    local docker = "/usr/share/napcat/docker.json" 
    local cmd = string.format("/usr/share/napcat/napcat -p %s -t %s -c %s >/dev/null &", port, token, docker) 
    if os.execute(cmd) then 
        luci.template.render(name.."/app", { 
            Port = port,
            -- Token = token
        }) 
    end
end