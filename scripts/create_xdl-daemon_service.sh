echo "[Unit]
Description=XDL Daemon Server

[Service]
User=root
WorkingDirectory=/root/xdm_bot
ExecStart=dart run bin/dld.server.dart
Restart=always

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/xdld-server.service

systemctl daemon-reload
systemctl start xdld-server