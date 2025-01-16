#!/bin/bash

# 当前脚本版本
SCRIPT_VERSION="1.0.0"
# 远程脚本地址
REMOTE_SCRIPT_URL="https://github.com/xyyyyxx/adg/raw/refs/heads/main/adg.sh"  # 替换为实际远程脚本地址
# 当前脚本路径
CURRENT_SCRIPT_PATH="$0"
# 快捷命令路径
SHORTCUT_PATH="/usr/local/bin/adg"

# 文件更新配置
FILE_URL="https://raw.githubusercontent.com/Leev1s/FAK-DNS/master/converted/FAK-DNS.txt"
TARGET_DIR="/opt/AdGuardHome"
TARGET_FILE="$TARGET_DIR/FAK-DNS.txt"

# AdGuard Home 服务名（请根据实际情况调整）
ADGUARD_SERVICE="AdGuardHome"

# 检查目标文件夹
check_target_dir() {
    if [ ! -d "$TARGET_DIR" ]; then
        echo "创建目标文件夹：$TARGET_DIR"
        sudo mkdir -p "$TARGET_DIR"
    fi
}

# 下载并替换文件
update_file() {
    echo "正在下载文件..."
    if curl -o "$TARGET_FILE.tmp" -fsSL "$FILE_URL"; then
        echo "文件下载成功，替换原文件..."
        sudo mv "$TARGET_FILE.tmp" "$TARGET_FILE"
        sudo chmod 644 "$TARGET_FILE"
        echo "文件更新完成，存放路径：$TARGET_FILE"
        restart_adguard
    else
        echo "文件下载失败，请检查网络或地址是否正确。"
        [ -f "$TARGET_FILE.tmp" ] && rm "$TARGET_FILE.tmp"
        exit 1
    fi
}

# 设置定时任务
set_cron_job() {
    echo -n "请输入循环更新的小时数（如每6小时更新，请输入6）："
    read hours
    if ! [[ "$hours" =~ ^[0-9]+$ ]]; then
        echo "输入无效，请输入一个数字！"
        exit 1
    fi
    cron_interval="0 */$hours * * * $SHORTCUT_PATH 2"
    echo "设置定时任务，每${hours}小时更新一次..."
    (crontab -l 2>/dev/null | grep -v "$SHORTCUT_PATH"; echo "$cron_interval") | crontab -
    echo "定时任务设置完成。"
    restart_adguard
}

# 删除文件
uninstall_file() {
    if [ -f "$TARGET_FILE" ]; then
        echo "正在删除文件：$TARGET_FILE"
        sudo rm -f "$TARGET_FILE"
        echo "文件已成功删除！"
    else
        echo "未找到目标文件，无需删除。"
    fi
}

# 更新脚本
update_script() {
    echo "正在检查脚本更新..."
    if REMOTE_SCRIPT=$(curl -fsSL "$REMOTE_SCRIPT_URL"); then
        # 从远程脚本中提取版本号
        REMOTE_VERSION=$(echo "$REMOTE_SCRIPT" | grep -oP '(?<=SCRIPT_VERSION=")[^"]+')
        echo "远程脚本版本：$REMOTE_VERSION"
        echo "当前脚本版本：$SCRIPT_VERSION"
        if [ "$REMOTE_VERSION" != "$SCRIPT_VERSION" ]; then
            echo "检测到新版本，正在更新脚本..."
            echo "$REMOTE_SCRIPT" > "$SHORTCUT_PATH.tmp"
            sudo mv "$SHORTCUT_PATH.tmp" "$SHORTCUT_PATH"
            sudo chmod +x "$SHORTCUT_PATH"
            echo "脚本更新成功，重新启动脚本..."
            exec "$SHORTCUT_PATH"
        else
            echo "当前脚本已是最新版本。"
        fi
    else
        echo "无法获取远程脚本，请检查网络连接或远程地址。"
        exit 1
    fi
}

# 重启 AdGuard Home
restart_adguard() {
    echo "正在重启 AdGuard Home 服务..."
    if /etc/init.d/$ADGUARD_HOME_SERVICE restart; then
        echo "AdGuard Home 服务重启成功！"
    else
        echo "重启 AdGuard Home 服务失败，请检查服务名是否正确。"
        exit 1
    fi
}

# 创建快捷命令
create_shortcut() {
    if [ ! -f "$SHORTCUT_PATH" ]; then
        echo "创建快捷命令：adg"
        sudo cp "$CURRENT_SCRIPT_PATH" "$SHORTCUT_PATH"
        sudo chmod +x "$SHORTCUT_PATH"
        echo "快捷命令已创建，可通过 'adg' 启动脚本。"
    else
        echo "快捷命令已存在：adg"
    fi
}

# 主菜单
main_menu() {
    echo "=================================="
    echo "  文件管理脚本菜单 (版本 $SCRIPT_VERSION)"
    echo "=================================="
    echo "1. 设置定时更新文件"
    echo "2. 手动强制更新文件"
    echo "3. 一键卸载当前文件"
    echo "4. 检查并更新脚本"
    echo "0. 退出"
    echo "=================================="
    echo -n "请输入操作编号："
    read choice

    case $choice in
        1)
            check_target_dir
            set_cron_job
            ;;
        2)
            check_target_dir
            update_file
            ;;
        3)
            uninstall_file
            ;;
        4)
            update_script
            ;;
        0)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效输入，请重新选择。"
            main_menu
            ;;
    esac
}

# 创建快捷命令
create_shortcut

# 启动菜单
main_menu
