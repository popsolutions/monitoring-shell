echo "config Prometheus exporter postgre"


echo -n "Enter strong password to user: " 
read password
user = postgres_exporter

mkdir -p /opt/prometheus/postgres_exporter 
cd /opt/prometheus/postgres_exporter

# get last version postgres_exporter prometheus
VERSION=$(curl -s https://api.github.com/repos/prometheus-community/postgres_exporter/releases/latest|grep tag_name|cut -d '"' -f 4|sed 's/v//')

wget https://github.com/prometheus-community/postgres_exporter/releases/download/v$VERSION/postgres_exporter-$VERSION.linux-amd64.tar.gz

tar -xf postgres_exporter-$VERSION.linux-*.tar.gz

cp postgres_exporter-$VERSION.linux-*/postgres_exporter /usr/local/bin

cat > /opt/prometheus/postgres_exporter/postgres_exporter.env <<EOL
DATA_SOURCE_NAME="postgresql://$user:$password@localhost:5432/postgres?sslmode=disable"
EOL

cat > /etc/systemd/system/postgres_exporter.service <<EOL
[Unit]
Description=Prometheus exporter for Postgresql
Wants=network-online.target
After=network-online.target

[Service]
User=$user
Group=$user
WorkingDirectory=/opt/prometheus/postgres_exporter
EnvironmentFile=/opt/prometheus/postgres_exporter/postgres_exporter.env
ExecStart=/usr/local/bin/postgres_exporter --web.listen-address=:9187 --web.telemetry-path=/metrics
Restart=always

[Install]
WantedBy=multi-user.target
EOL

adduser --system --no-create-home --group --disabled-login $user 
chown -R $user:$user /opt/prometheus/postgres_exporter

systemctl daemon-reload
systemctl enable --now postgres_exporter

echo "---"

echo 'start config database user'

su -s /bin/bash postgres

cat > create_user.sql <<EOL
CREATE USER $user WITH PASSWORD '$(password)';
GRANT CONNECT ON DATABASE postgres TO $user;
GRANT USAGE ON SCHEMA pg_catalog TO $user;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO $user;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO $user;
EOL

psql -f create_user.sql


