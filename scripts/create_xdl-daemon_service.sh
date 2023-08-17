echo "[Unit]
Description=XDL Daemon Server

[Service]
User=root
WorkingDirectory=/root/xdm_bot
ExecStart=dart bin/dld.server.dart
Restart=always

[Install]
WantedBy=multi-user.target
" > echo xdld-server

systemctl daemon-reload
systemctl start xdld-server