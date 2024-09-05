echo "config Prometheus node exporter"

user = node_exporter
repo = prometheus
mkdir -p /opt/prometheus/$user
cd /opt/prometheus/$user

# get last version postgres_exporter prometheus
VERSION=$(curl -s https://api.github.com/repos/$repo/$user/releases/latest|grep tag_name|cut -d '"' -f 4|sed 's/v//')

wget https://github.com/prometheus/node_exporter/releases/download/v$VERSION/postgres_exporter-$VERSION.linux-amd64.tar.gz

tar -xf node_exporter-$VERSION.linux-*.tar.gz

cp node_exporter-$VERSION.linux-*/node_exporter /usr/local/bin


cat > /etc/systemd/system/node_exporter.service <<EOL
[Unit]
Description=Prometheus exporter for node
Wants=network-online.target
After=network-online.target

[Service]
User=$user
Group=$user
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.systemd

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable --now node_exporter
systemctl restart node_exporter.service

