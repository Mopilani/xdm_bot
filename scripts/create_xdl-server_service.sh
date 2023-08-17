echo "[Unit]
Description=XDM Download Server Service

[Service]
User=root
WorkingDirectory=/root/xdm_bot
ExecStart=dart bin/dl.server.dart
Restart=always

[Install]
WantedBy=multi-user.target
" > echo xdl-server

systemctl daemon-reload
systemctl start xdl-server