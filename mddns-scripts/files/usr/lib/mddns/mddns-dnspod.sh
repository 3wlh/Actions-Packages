#!/bin/sh
#
# @provider: dnspod
# @display: DNSPod (腾讯云)
# @key_field: secret_id
# @secret_field: secret_key
#

log_info() { echo "[DNSPod] $1" >&2; }
log_ok()   { echo "[DNSPod] ✓ $1" >&2; }
log_err()  { echo "[DNSPod] ✗ $1" >&2; }

MDDNS_BIN="${MDDNS_BIN:-mddns}"
ENDPOINT="https://dnspod.tencentcloudapi.com"

# 用法: mddns-dnspod.sh <action> <domain> <sub> <type> [ip] [ttl] [record_id] [key] [secret]
ACTION="$1"; DOMAIN="$2"; SUB="$3"; TYPE="$4"; IP="$5"; TTL="$6"; RECORD_ID="$7"; KEY="$8"; SECRET="$9"

SECRET_ID="${KEY:-${DNSPOD_SECRET_ID}}"
SECRET_KEY="${SECRET:-${DNSPOD_SECRET_KEY}}"

if [ -z "$SECRET_ID" ] || [ -z "$SECRET_KEY" ]; then
    echo "错误: 请提供 key 和 secret" >&2
    exit 1
fi

# 检测 HTTP 客户端
if command -v curl >/dev/null 2>&1; then
    HTTP_CLIENT="curl"
elif command -v wget >/dev/null 2>&1; then
    HTTP_CLIENT="wget"
else
    echo "错误: 需要 curl 或 wget" >&2
    exit 1
fi

sign() {
    if ! command -v "$MDDNS_BIN" >/dev/null 2>&1; then
        log_err "签名工具不可用: $MDDNS_BIN"
        return 1
    fi
    result=$(printf '%s' "$1" | "$MDDNS_BIN" -sha256 -hmac "$SECRET_KEY" 2>&1)
    if [ -z "$result" ]; then
        log_err "签名失败: $MDDNS_BIN 无输出"
        return 1
    fi
    printf '%s' "$result"
}

send_request() {
    action="$1"; shift
    ts=$(date +%s)
    nonce="$(date +%s)$$"
    p="Action=$action&Nonce=$nonce&Region=&SecretId=$SECRET_ID&Timestamp=$ts&Version=2021-03-23"
    for arg in "$@"; do p="$p&$arg"; done
    sig=$(sign "$p")
    body="${p}&Signature=${sig}"
    if [ "$HTTP_CLIENT" = "curl" ]; then
        curl -s -X POST "$ENDPOINT" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "$body"
    else
        wget -q -O - \
            --header="Content-Type: application/x-www-form-urlencoded" \
            --post-data="$body" \
            "$ENDPOINT"
    fi
}

get_main_domain() {
    echo "$1" | awk -F. '{n=split($0,a,"."); print a[n-1]"."a[n]}'
}

get_record() {
    domain="$1"; sub="$2"; type="$3"
    main=$(get_main_domain "$domain")
    log_info "查询记录: ${sub}.${domain} (${type})"
    result=$(send_request "DescribeRecordList" "Domain=${main}")
    id=$(printf '%s' "$result" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    val=$(printf '%s' "$result" | grep -o '"value":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$id" ]; then
        log_ok "查询记录成功: ${sub}.${domain} (${type}) -> ID=${id}, Value=${val}"
        echo "$id $val"
    else
        log_err "查询记录失败: ${sub}.${domain} (${type}) 未找到记录"
        log_err "API返回: $result"
    fi
}

add_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"
    main=$(get_main_domain "$domain")
    log_info "添加记录: ${sub}.${domain} (${type}) -> ${val}"
    result=$(send_request "CreateRecord" "Domain=${main}" "Name=${sub}" "Type=${type}" "Value=${val}" "TTL=${ttl}")
    if printf '%s' "$result" | grep -q '"id"'; then
        log_ok "添加记录成功: ${sub}.${domain} (${type}) -> ${val}"
        echo "添加成功"
    else
        log_err "添加记录失败: ${sub}.${domain} (${type}) -> ${val}"
        log_err "API返回: $result"
    fi
}

update_record() {
    domain="$1"; sub="$2"; type="$3"; val="$4"; ttl="$5"; id="$6"
    main=$(get_main_domain "$domain")
    log_info "更新记录: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
    result=$(send_request "ModifyRecord" "Domain=${main}" "RecordId=${id}" "Name=${sub}" "Type=${type}" "Value=${val}" "TTL=${ttl}")
    if printf '%s' "$result" | grep -q '"id"'; then
        log_ok "更新记录成功: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
        echo "更新成功"
    else
        log_err "更新记录失败: ${sub}.${domain} (${type}) -> ${val} (ID=${id})"
        log_err "API返回: $result"
    fi
}

delete_record() {
    domain="$1"; id="$2"
    main=$(get_main_domain "$domain")
    log_info "删除记录: ${domain} (ID=${id})"
    result=$(send_request "DeleteRecord" "Domain=${main}" "RecordId=${id}")
    if printf '%s' "$result" | grep -q '"id"'; then
        log_ok "删除记录成功: ${domain} (ID=${id})"
        echo "删除成功"
    else
        log_err "删除记录失败: ${domain} (ID=${id})"
        log_err "API返回: $result"
    fi
}

case "$ACTION" in
    get)    get_record "$DOMAIN" "$SUB" "$TYPE" ;;
    add)    add_record "$DOMAIN" "$SUB" "$TYPE" "$IP" "$TTL" ;;
    update) update_record "$DOMAIN" "$SUB" "$TYPE" "$IP" "$TTL" "$RECORD_ID" ;;
    delete) delete_record "$DOMAIN" "$RECORD_ID" ;;
    *)      echo "用法: $0 {get|add|update|delete} <参数...>" >&2; exit 1 ;;
esac
