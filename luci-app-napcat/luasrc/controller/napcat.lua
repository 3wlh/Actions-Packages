module("luci.controller.napcat", package.seeall)

function index()
    entry({"admin", "services", "napcat"}, firstchild(), _("NapCat"), 90).dependent = true
    entry({"admin", "services", "napcat", "app"}, call("app"), _("Settings"), 10).leaf = true
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

function app()
    local port, token =  get_port(),get_token()
    local docker="/usr/share/napcat/docker.json"
    local cmd = string.format("/usr/share/napcat/napcat -p %s -t %s -c %s >/dev/null &",port, token,docker)
    if os.execute(cmd) then
        luci.template.render("napcat/app", {
            Port = port,
            Token = token
        })
    end
end