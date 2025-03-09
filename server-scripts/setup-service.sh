#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo"
    exit 1
fi

# Get the current working directory
WORKING_DIR=$(pwd)

# Create the service file content
cat > lifejournal.service << EOL
[Unit]
Description=Life Journal Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${WORKING_DIR}
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOL

# Move the service file to systemd directory
mv lifejournal.service /etc/systemd/system/

# Set proper permissions
chmod 644 /etc/systemd/system/lifejournal.service

echo "Service file created and moved to systemd directory"

# Reload systemd daemon
systemctl daemon-reload

echo "Reloaded systemd daemon"

# Enable and start the service
systemctl enable lifejournal.service

echo "Enabled lifejournal.service"

# Check if service is already running before starting
if systemctl is-active --quiet lifejournal.service; then
    echo "Service is already running"
else
    systemctl start lifejournal.service
    echo "Started lifejournal.service"
fi

echo "Service has been created and started successfully!"
echo "You can check the status with: systemctl status lifejournal.service"
