 
 # Create a service file in /lib/systemd/system
 sudo nano /lib/systemd/system/hello_env.service

 # Content
[Unit]
  Description=hello_env.js - making your environment variables rad
  Documentation=https://example.com
  After=network.target
[Service]
  Environment=NODE_PORT=3001
  Type=simple
  User=ubuntu
  ExecStart=/usr/bin/node /home/ubuntu/hello_env.js
  Restart=on-failure
[Install]
  WantedBy=multi-user.target