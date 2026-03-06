#!/bin/zsh

# Flutter 发布脚本 - 构建 APK 并复制到 release 目录

echo "开始构建 Release 版本..."

# Flutter 路径
FLUTTER="$HOME/flutter/bin/flutter"

# 构建 Release APK
$FLUTTER build apk --release

if [ $? -eq 0 ]; then
    echo "构建成功！"

    # 确保 release 目录存在
    mkdir -p release

    # 复制 APK 到 release 目录
    cp build/app/outputs/flutter-apk/app-release.apk release/super_fitness.apk

    echo "APK 已复制到: release/super_fitness.apk"
else
    echo "构建失败！"
    exit 1
fi
