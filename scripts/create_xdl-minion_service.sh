echo "[Unit]
Description=XDL Minion Server

[Service]
User=root
WorkingDirectory=/root/xdm_bot
ExecStart=dart run bin/dlm.server.dart
Restart=always

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/xdlm-server.service

systemctl daemon-reload
systemctl start xdlm-server