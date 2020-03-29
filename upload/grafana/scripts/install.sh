# 1) Install from YUM repository


cat >/etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF


sudo yum install -y grafana


# 2) Start the server

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server

sudo systemctl enable grafana-server.service


sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload