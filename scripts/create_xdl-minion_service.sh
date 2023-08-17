echo "[Unit]
Description=XDL Minion Server

[Service]
User=root
WorkingDirectory=/root/xdm_bot
ExecStart=dart bin/dlm.server.dart
Restart=always

[Install]
WantedBy=multi-user.target
" > echo xdlm-server

systemctl daemon-reload
systemctl start xdlm-server