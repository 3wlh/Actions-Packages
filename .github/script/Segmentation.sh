#!/bin/bash
PACKAGES_PATH="${1}"
PACKAGES_URL="${2}"
PACKAGES_NAME=(${3})

wget -qO- "${PACKAGES_URL}/Packages" | \
while IFS= read -r LINE; do
    for NAME in "${PACKAGES_NAME[@]}"; do
        # 1. 将 [ 改为 [[ 以更安全地支持通配符 *
        if [[ "$LINE" == "Filename:"*${NAME}* ]]; then
            # 2. 给 ${NAME} 加上双引号防止报错
            FILE=$(echo "$LINE" | grep -Eo "${NAME}".*)
            if [[ -z "$FILE" ]]; then
                # echo "No file found in line, skipping"
                continue
            fi
            Download_URL="${PACKAGES_URL}${FILE}"
            if [[ ! -f "${PACKAGES_PATH}/${FILE}" ]];then
                find "${PACKAGES_PATH}" -type f -name "*${NAME}*" -exec rm -f {} \;
                Download "${PACKAGES_PATH}" "${Download_URL}"
            else
                # 5. 【修复】修复颜色代码 \e 无法被正确解析的问题
                echo "$(date '+%Y-%m-%d %H:%M:%S')$'\e[1;32m' - 【${FILE}】插件无更新.$'\e[0m'"
            fi   
        fi
    done
done