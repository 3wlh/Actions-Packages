module("luci.controller.scriptmsg", package.seeall)

function index()
    entry({"admin", "system", "scriptmsg"}, firstchild(), _("在线配置"), 90).dependent = true
    entry({"admin", "system", "scriptmsg", "settings"}, cbi("scriptmsg/settings"), _("Settings"), 10).leaf = true
    entry({"admin", "system", "scriptmsg", "execute"}, call("exec_msg"), _("执行命令"), 20).leaf = true
    entry({"admin", "system", "scriptmsg", "run"}, call("exec_run"), nil).leaf = true
    entry({"admin", "system", "scriptmsg", "stop"}, call("exec_stop"), nil).leaf = true
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
function sess_token(sid) 
    local ubus = require "ubus" 
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
    return nil
end

-- 生成32位随机字符串（字母+数字）
function get_token()
    -- 定义字符集（数字+小写字母，满足32位需求）
    local charset = "0123456789abcdefghijklmnopqrstuvwxyz"
    local charset_len = #charset
    local random_str = ""
    -- 循环32次生成随机字符
    for i = 1, 32 do
        -- 随机选取字符集中的字符（math.random兼容所有Lua环境）
        local random_idx = math.random(1, charset_len)
        random_str = random_str .. charset:sub(random_idx, random_idx)
    end
    return random_str
end

-- 生成解密密钥（Key）的函数
local function get_key()
    local mac = nil
    -- 获取eth0 MAC（优先ip命令）
    local ip_cmd = io.popen("ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}'")
    if ip_cmd then
        mac = ip_cmd:read("*a"):gsub("%s+", "")
        ip_cmd:close()
    end
    -- 备用路径（sysfs）
    if not mac or mac == "" then
        local mac_file = io.open("/sys/class/net/eth0/address", "r")
        if mac_file then
            mac = mac_file:read("*a"):gsub("%s+", "")
            mac_file:close()
        end
    end
    -- 生成解密Key（MAC为空时返回空）
    local key = ""
    if mac and mac ~= "" then
        -- 安全拼接命令，避免注入风险
        local md5_cmd = io.popen(string.format("echo -n '%s' | md5sum | awk '{print $1}' | cut -c9-24", mac:gsub("'", "'\\''")))
        if md5_cmd then
            key = md5_cmd:read("*a"):gsub("%s+", "")
            md5_cmd:close()
        end
    end
    return key  
end

function exec_msg()
    local http = require "luci.http"
    http.header("Content-Type", "text/html; charset=utf-8")
    local sid = http.getcookie("sysauth") or http.getcookie("sysauth_http") or http.getcookie("sysauth_https") 
    if not sid then
        http.write("Error: unable to get session id") 
        return 
    end
    local port, token = get_port(), sess_token(sid) -- get_port()  
    if not token then
        luci.template.render("napcat/app")
        http.write("Error: failed to get token")
        return
    end
    local port, token =  get_port(),get_token() 
    local cmd = string.format("/usr/share/ssemsg/sse_msg -p %s -t %s >/dev/null &", port, token)
    if os.execute(cmd) then
         luci.template.render("scriptmsg/exec", {
            Port = port,
            --Token = token
        })
    end
end

local function get_variable()
    local uci = require("luci.model.uci").cursor()
    -- 正确读取列表型配置节：@general[]（适配config general不带名称的场景）
    local config = {
        url = uci:get("scriptmsg", "@general[0]", "script_url") or "",
        key = uci:get("scriptmsg", "@general[0]", "script_key") or get_key(),
    }
    uci:unload("scriptmsg")
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
    local json = require("luci.jsonc")
    local ok, data = pcall(json.parse, request_body)
    if not ok or type(data) ~= "table" then
        luci.http.write(string.format('{"msg":"%s"}', data))
        return
    end
    -- 提取字段
    --local exec = data.cmd
    local port = data.port
    local token = data.token
    local cfg = get_variable()
    
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
    luci.http.write(string.format('{"msg":"%s"}', token))
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
    local json = require("luci.jsonc")
    local ok, data = pcall(json.parse, request_body)
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
    luci.http.write('{"msg":"停止命令已下发"}')
end