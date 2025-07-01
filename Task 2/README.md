# Server/proxmox 


## 1- create non-root user & give it a sudo permision.
```
useradd -m -d <user-name> /home/<user-name>
passwd <user-name>
usermod -aG sudo <user-name>

#check user is appended in sudo group
cat /etc/groups
# User privilege specification
echo "<user-name>  ALL=(ALL:ALL)   NOPASSWD: ALL" >> /etc/sudoers
```
## 2- SSH security Config 
- ##### change ssh port 
   ```
   echo " port 2222" >> /etc/ssh/sshd_config
   ```
- #### enable ssh only with public key 
   ```
   vim /etc/ssh/sshd_config
   #add this lines 
   PubkeyAuthentication yes
   PasswordAuthentication no
   ```
## 3- securing Proxmox Console
  - #### create a subdomain that points to the server IP and  use Let's encrypt to generate a free wildcard certificate so we can use in your server. 
       ```
       sudo apt install nginx certbot
    ```
       create wildecard certificate
    ```
    sudo certbot certonly --manual --preferred-challenges dns -d "*.yourdomain.com" -d "yourdomain.com"
    ```
     Generate the SSL Certificate
     - Run the certbot command. During the process:
    - Certbot will give you a TXT record to add to your DNS
    - Add this TXT record in your DNS management panel
    - The record name will be something like _acme-challenge.yoursubdomain 
    - Press Enter in certbot to continue verification
    Wait a few minutes for the DNS changes to propagate. You can check with:
    ```
    nslookup yoursubdomain.yourdomain.com
    ```
## 4- Create HTTPASS
```
#create HTTPASS with username, after that you can enter password
touch .htpasswd
htpasswd /etc/nginx/.htpasswd <username>
```

## 5-Create Nginx configuration
```
vi /etc/nginx/sites-available/proxmox
```
- Add this configuration:
```
if ($host = <domain-name>) {
        return 301 https://$host$request_uri;
server {
    listen 80;
    listen [::]:80;
    server_name <domain-name>;
    location / {
            #to make http://ip forbiden 
            return 403;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name <domain-name>;

    ssl_certificate /etc/letsencrypt/live/<domain-name>-0001/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/<domain-name>-0001/privkey.pem; # managed by Certbot

    # Security headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
       #to make https://ip forbiden 
    if ($host != "<domain-name>"){
            return 403;

    }


    location / {
        # Basic authentication (optional - you can remove these 2 lines if not needed)
        auth_basic "Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # Proxy to local Proxmox instance
        proxy_pass https://127.0.0.1:8006;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (ESSENTIAL for console access)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Disable buffering for real-time console
        proxy_buffering off;
        proxy_cache off;

        # Increase timeouts for console sessions and large operations
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;

        # Allow large file uploads (ISO files, backups, etc.)
        client_max_body_size 0;

        # Accept Proxmox self-signed certificate
        proxy_ssl_verify off;
    }
}
```

- Enable the Configuration
```
# Enable the site
ln -s /etc/nginx/sites-available/proxmox /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# get SSL certificate
certbot --nginx -d yourdomain.com

nginx -t
systemctl reload nginx
```
## 6- Set firewall rules  .
```
# Allow localhost access 
iptables -I INPUT 1 -s 127.0.0.1 -p tcp --dport 8006 -j ACCEPT

# Allow loopback interface
iptables -I INPUT 1 -i lo -j ACCEPT

# Allow your local network 
iptables -I INPUT 3 -s 10.0.0.1/24 -p tcp --dport 8006 -j ACCEPT

# Block everything else to port 8006 
iptables -A INPUT -p tcp --dport 8006 -j DROP
```

- Check :
```
 iptables -L INPUT -n --line-numbers | grep -E "(lo|127.0.0.1|8006)"
```




   
