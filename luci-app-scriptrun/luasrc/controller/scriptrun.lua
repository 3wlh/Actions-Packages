local name = "scriptrun"
module("luci.controller."..name, package.seeall) 

function index()
    entry({"admin", "system", name}, firstchild(), _("在线配置"), 90).dependent = true
    entry({"admin", "system", name, "settings"}, cbi(name.."/settings"), _("Settings"), 10).leaf = true
    entry({"admin", "system", name, "execute"}, call("exec_cmd"), _("执行命令"), 20).leaf = true
    entry({"admin", "system", name, "run"}, call("exec_run"), nil).leaf = true
    entry({"admin", "system", name, "stop"}, call("exec_stop"), nil).leaf = true
end

-- 输出错误日志
local errors = {}
function log_error(msg)
    local safe_msg = msg:gsub("'", "'\\''")
    table.insert(errors, safe_msg)
    local cmd = string.format("logger -t %s '%s error: %s'",name ,name, safe_msg )
    os.execute(cmd)
end

-- 生成随机端口的函数
function get_port()
    math.randomseed(os.time())
    for _ = 1, 100 do
        local port = math.random(1024, 65535)
        local cmd = string.format("netstat -tunl | grep -qw :%d", port)
        local ret = os.execute(cmd)
        -- 返回非0表示端口未占用
        if ret ~= 0 then
            return port
        end
    end
end

-- 获取登录token
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
        log_error("未获取到列表[ubus]")
        return nil
    end
    local session_data = conn:call("session", "get", { ubus_rpc_session = sid }) 
    conn:close()
    if session_data and session_data.values and session_data.values.token then
        return session_data.values.token
    elseif session_data and session_data.token then
        return session_data.token
    end
    return nil
end

-- 生成解密密钥（Key）的函数
local function get_key()
    -- 获取eth0 MAC（优先ip命令）
    local mac = luci.util.exec("ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'")
    if mac then
        mac = mac:gsub("%s+", "")
    end
    -- 备用方法
    if not mac or mac == "" then
        local mac = luci.util.exec("cat /sys/class/net/eth0/address 2>/dev/null")
        if mac then
            mac = mac:gsub("%s+", "")
        end
    end
    local safe_mac = mac:gsub("'", "'\\''")
    local key = luci.util.exec(string.format("echo -n '%s' | md5sum | awk '{print $1}' | cut -c9-24", safe_mac))
    if key then
        key = key:gsub("%s+", "")
    end
    return mac, key
end

function get_data()
    return get_port(), sess_token()
end

function exec_cmd()
    local port, token = get_data()  
    if #errors > 0 then
        luci.template.render(name.."/errlog", { errors = errors })
        return
    end
    local cmd = string.format("/usr/share/sseconsole/sseconsole -p %s -t %s >/dev/null &", port, token)
    if os.execute(cmd) then
         luci.template.render(name.."/exec", {
            Port = port,
            --Token = token
        })
    end
end

local function get_config()
    local uci = require("luci.model.uci").cursor()
    -- 正确读取列表型配置节：@general[]（适配config general不带名称的场景）
    local config = {
        url = uci:get(name, "@general[0]", "script_url") or "",
        key = uci:get(name, "@general[0]", "script_key") or get_key(),
    }
    uci:unload(name)
    return config
end

-- 执行命令
function exec_run()
    luci.http.header("Content-Type", "application/json; charset=utf-8")
    -- 读取原始 POST 数据
    local request_body = luci.http.content()
    if not request_body then
        luci.http.write('{"msg":"空请求体"}')
        return
    end    
    -- 解析 JSON
    local ok, data = pcall(luci.jsonc.parse, request_body)
    if not ok or type(data) ~= "table" then
        luci.http.write(string.format('{"msg":"%s"}', data))
        return
    end
    -- 提取字段
    --local exec = data.cmd
    local port = data.port
    local token = data.token
    local cfg = get_config()
    
    -- 参数验证
    if not port or tonumber(port) == nil then
        luci.http.write('{"msg":"端口无效"}')
        return
    end
    -- 验证 token
    if not token then
        luci.http.write('{"msg":"token 无效"}')
        return
    end
    -- 获取配置
    local url = cfg.url:gsub("'", "'\\''") -- 转义单引号防注入
    local key = cfg.key:gsub("'", "'\\''") -- 转义单引号防注入
    
    local exec = string.format("wget -qO- '%s' | bash -s '%s'", url,key)
    --local exec = "ping 127.1 -c 20"
    -- 后台执行
    local safe_exec = string.format(
        "wget -qO- --post-data='%s' http://127.0.0.1:%s/exec >/dev/null",
        exec,
        port)
    os.execute(safe_exec)
    luci.http.write(string.format('{"msg":"%s"}', exec))
end

function exec_stop()
     luci.http.header("Content-Type", "application/json; charset=utf-8")
    -- 读取原始 POST 数据
    local request_body = luci.http.content()
    if not request_body then
        luci.http.write('{"msg":"空请求体"}')
        return
    end    
    -- 解析 JSON
    local ok, data = pcall(luci.jsonc.parse, request_body)
    if not ok or type(data) ~= "table" then
        luci.http.write(string.format('{"msg":"%s"}', data))
        return
    end
    -- 提取字段
    --local exec = data.cmd
    local port = data.port
    local token = data.token
    -- 参数验证
    if not port or tonumber(port) == nil then
        luci.http.write('{"msg":"端口无效"}')
        return
    end
    -- 验证 token
    if not token then
        luci.http.write('{"msg":"token 无效"}')
        return
    end 
    local cmd = string.format(
        "wget -qO- --post-data='exec' http://127.0.0.1:%s/exec >/dev/null",
        port
    )
    os.execute(cmd)
    luci.http.write('{"msg":"已停止命令"}')
end