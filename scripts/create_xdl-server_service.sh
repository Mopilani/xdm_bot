echo "[Unit]
Description=XDM Download Server Service

[Service]
User=root
WorkingDirectory=/root/xdm_bot
ExecStart=dart run bin/dl.server.dart
Restart=always

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/xdl-server.service

systemctl daemon-reload
systemctl start xdl-server