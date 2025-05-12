#!/bin/bash

# 切换到 root 用户
sudo -i

# 更新系统并安装必要软件
sudo apt update
sudo apt install nginx unzip -y
sudo systemctl restart nginx && sudo systemctl enable nginx

# 创建工作目录并进入
mkdir -p /root/test && cd /root/test

# 下载文件
wget https://github.com/koyebs/ray-cf/raw/refs/heads/main/s390x-Apache-Plus.zip
wget https://github.com/koyebs/ray-cf/raw/refs/heads/main/s390x-cf.zip

sleep 5

# 解压并重命名
unzip s390x-Apache-Plus.zip && rm s390x-Apache-Plus.zip
unzip s390x-cf.zip && rm s390x-cf.zip
mv Apache-s390x-Plus Apache
mv s390x-cf CF

# 赋予可执行权限
chmod +x *

# 创建 Systemd 服务文件
cat >/etc/systemd/system/Apache.service <<-EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target

[Service]
User=root
NoNewPrivileges=true

Environment="PORT8=33333"
Environment="WSPATH=9388151a-cbe9-11ee-884e-325096b39f47"
Environment="UUID=9388151a-cbe9-11ee-884e-325096b39f47"

ExecStart=/root/test/Apache
Type=simple
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
systemctl daemon-reload
systemctl enable Apache.service
systemctl start Apache.service &

sleep 5

# 防火墙设置
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 33333 -j ACCEPT

# 保存当前的规则
sudo bash -c "iptables-save > /etc/iptables/rules.v4" 

# 保留 iptables 规则（你需要确保 /etc/iptables/rules.v4 文件存在并配置）
sudo iptables-restore < /etc/iptables/rules.v4

# 系统清理
yes | sudo rm -rf /tmp/*
sudo journalctl --vacuum-size=1M
sudo apt-get clean
sudo apt-get autoremove -y
sudo journalctl --vacuum-time=1s
rm -rf ~/.bash_history
history -c

# 重启系统以测试服务是否自启动
reboot
