
apt update && apt install -y python3 python3-pip nginx certbot python3-certbot-nginx

pip3 install flask gunicorn
mkdir -p /opt/flask-app

cat <<EOF > /opt/flask-app/app.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "<h1>Olá Mundo! Envio isto de um servidor na Google Cloud criado através de Terraform.</h1>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

cat <<EOF > /etc/systemd/system/flask.service
[Unit]
Description=Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/opt/flask-app
ExecStart=/usr/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask
systemctl start flask


cat <<EOF > /etc/nginx/sites-available/flask
server {
    listen 80;
    server_name ${server_ip};

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/flask /etc/nginx/sites-enabled
systemctl restart nginx