#!/bin/sh

tee /etc/apt/sources.list <<-'EOF'
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib
EOF
apt clean
