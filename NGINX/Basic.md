Absolutely! Here's a basic NGINX learning roadmap with commands and examples, presented clearly in English with helpful icons.

---

# 🚀 Basic NGINX Learning Roadmap

NGINX (pronounced "engine-x") is a powerful, high-performance open-source web server, reverse proxy, and load balancer. It's renowned for its stability, rich feature set, simple configuration, and low resource consumption.

## 🌟 1. Understanding the Basics

Before diving into commands, let's understand some fundamental NGINX concepts.

* **Web Server**: NGINX can serve static content (HTML, CSS, JavaScript, images) directly to clients.
* **Reverse Proxy**: NGINX sits in front of other web servers (like Apache, Node.js, Python apps) and forwards client requests to them. This is its most common use case for modern applications.
* **Load Balancer**: Distributes incoming network traffic across multiple backend servers to ensure no single server becomes a bottleneck.
* **Event-Driven Architecture**: NGINX uses a non-blocking, event-driven approach to handle requests, allowing it to serve thousands of concurrent connections efficiently with minimal resources.
* **Configuration Files**: NGINX's behavior is controlled by plain text configuration files, primarily `nginx.conf`.

---

## 📦 2. Installation

The first step is to get NGINX installed on your Linux system.

### Purpose

To make the NGINX web server software available on your system.

### Commands (for Ubuntu/Debian)

```bash
sudo apt update
sudo apt install nginx
```

### Explanation

* `sudo apt update`: Updates the package lists to ensure you're getting the latest version available from your repositories.
* `sudo apt install nginx`: Installs the NGINX package. The `sudo` command is used to execute commands with root (administrator) privileges, which is necessary for system-level installations.

### Example

```bash
sudo apt update
sudo apt install nginx
```
After installation, NGINX typically starts automatically.

---

## ⚙️ 3. Basic Service Management

Learn how to start, stop, restart, and check the status of the NGINX service.

### Purpose

To control the NGINX web server's runtime behavior.

### Commands (using `systemctl` for `systemd` systems)

* **Check NGINX status:**
    ```bash
    sudo systemctl status nginx
    ```
    * **Explanation**: Shows if NGINX is running, if there are any errors, and its process ID.

* **Start NGINX:**
    ```bash
    sudo systemctl start nginx
    ```
    * **Explanation**: Starts the NGINX service.

* **Stop NGINX:**
    ```bash
    sudo systemctl stop nginx
    ```
    * **Explanation**: Stops the NGINX service gracefully.

* **Restart NGINX:**
    ```bash
    sudo systemctl restart nginx
    ```
    * **Explanation**: Stops and then starts the NGINX service. Use this after significant configuration changes.

* **Reload NGINX (for configuration changes):**
    ```bash
    sudo systemctl reload nginx
    ```
    * **Explanation**: Loads new configuration without stopping and restarting the server. This is preferred for minor changes as it avoids downtime.

* **Enable NGINX (start at boot):**
    ```bash
    sudo systemctl enable nginx
    ```
    * **Explanation**: Configures NGINX to start automatically when the system boots up.

### Example

```bash
sudo systemctl status nginx
# Output will show if it's "active (running)" or otherwise.

sudo systemctl reload nginx
# Use this after you've edited configuration files.
```

---

## 📝 4. Understanding NGINX Configuration

NGINX's power comes from its flexible configuration. Understanding its structure is key.

### Purpose

To customize NGINX's behavior for serving content, acting as a proxy, etc.

### Key Configuration Files and Directories

* **`/etc/nginx/nginx.conf`**: The main NGINX configuration file. This often includes other files.
* **`/etc/nginx/sites-available/`**: Directory for virtual host (server block) configurations. You define your websites here.
* **`/etc/nginx/sites-enabled/`**: Directory where symlinks to files in `sites-available` are placed. NGINX only loads configurations from `sites-enabled`.
* **`/var/www/html`**: Default root directory for web content (static files).

### Basic Configuration Structure (`nginx.conf` simplified)

```nginx
# Global settings
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024; # How many connections a worker process can handle
}

http {
    # General HTTP settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Basic logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Include specific server block configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*; # This is where your website configs go
}
```

---

## 🌐 5. Serving Static Content (Basic Web Server)

Configure NGINX to serve simple HTML files.

### Purpose

To make your website's static files accessible via a web browser.

### Workflow

1.  Create a simple HTML file.
2.  Configure an NGINX **server block**.
3.  Enable the configuration.
4.  Test the configuration.
5.  Reload NGINX.

### Example: Serving `mywebsite.com`

1.  **Create a simple HTML file:**
    ```bash
    sudo mkdir -p /var/www/mywebsite.com/html
    echo "<h1>Welcome to My Website!</h1><p>Served by NGINX.</p>" | sudo tee /var/www/mywebsite.com/html/index.html
    ```

2.  **Create a new server block configuration file:**
    ```bash
    sudo nano /etc/nginx/sites-available/mywebsite.com
    ```
    Add the following content:
    ```nginx
    server {
        listen 80; # Listen for HTTP requests on port 80
        listen [::]:80; # Listen on IPv6 as well

        root /var/www/mywebsite.com/html; # Root directory for this website
        index index.html index.htm; # Default files to serve if directory is requested

        server_name mywebsite.com www.mywebsite.com; # Domain names this server block responds to

        location / {
            try_files $uri $uri/ =404; # Try to serve file, then directory, else 404
        }
    }
    ```
    * **`server` block**: Defines a virtual host for your website.
    * **`listen 80;`**: Tells NGINX to listen for incoming connections on port 80 (standard HTTP).
    * **`root`**: Specifies the directory where your website's files are located.
    * **`index`**: Defines the default file (e.g., `index.html`) to serve when a directory is requested.
    * **`server_name`**: Specifies the domain names this server block should respond to.
    * **`location /`**: Defines how to handle requests for paths within your website. `try_files` attempts to find a file, then a directory, and if neither exists, returns a 404 error.

3.  **Enable the configuration (create a symlink):**
    ```bash
    sudo ln -s /etc/nginx/sites-available/mywebsite.com /etc/nginx/sites-enabled/
    ```
    * **Explanation**: NGINX only reads configuration files from the `sites-enabled` directory. Creating a symbolic link (`ln -s`) is the standard way to enable a site.

4.  **Test NGINX configuration for syntax errors:**
    ```bash
    sudo nginx -t
    ```
    * **Explanation**: This command checks your configuration files for syntax errors without actually restarting the service. It's crucial after any changes.

    * **Example Output (Success):**
        ```
        nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
        nginx: configuration file /etc/nginx/nginx.conf test is successful
        ```

5.  **Reload NGINX to apply changes:**
    ```bash
    sudo systemctl reload nginx
    ```

6.  **Update your local hosts file (for testing locally):**
    If you don't have a DNS entry for `mywebsite.com`, you can temporarily add it to your computer's `hosts` file to point to your NGINX server's IP address.
    * On Linux/macOS: `sudo nano /etc/hosts`
    * On Windows: `C:\Windows\System32\drivers\etc\hosts`
    Add the line (replace `your_server_ip`):
    ```
    your_server_ip mywebsite.com www.mywebsite.com
    ```
7.  **Open a web browser** and navigate to `http://mywebsite.com`. You should see "Welcome to My Website!"

---

## 🔄 6. Basic Reverse Proxy

Configure NGINX to forward requests to another web server or application running on a different port (e.g., a Node.js app).

### Purpose

To serve applications running on non-standard ports or on different backend servers through NGINX on standard ports (like 80 or 443).

### Scenario

You have a Node.js application running on `localhost:3000` on your server, and you want users to access it via `app.example.com` on port 80.

### Example: Proxying to a Node.js app

1.  **Assume your Node.js app is running on port 3000.**

2.  **Create a new server block for your app:**
    ```bash
    sudo nano /etc/nginx/sites-available/app.example.com
    ```
    Add the following content:
    ```nginx
    server {
        listen 80;
        listen [::]:80;

        server_name app.example.com; # The domain name for your application

        location / {
            proxy_pass http://localhost:3000; # Forward requests to your Node.js app
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```
    * **`proxy_pass`**: The core directive for reverse proxying. It specifies the address and port of the backend server.
    * **`proxy_set_header`**: These lines pass along important headers from the client request to the backend server, which is often necessary for the backend application to function correctly (e.g., to know the original host).

3.  **Enable the configuration:**
    ```bash
    sudo ln -s /etc/nginx/sites-available/app.example.com /etc/nginx/sites-enabled/
    ```
4.  **Test NGINX configuration:**
    ```bash
    sudo nginx -t
    ```
5.  **Reload NGINX:**
    ```bash
    sudo systemctl reload nginx
    ```
6.  **Update your local hosts file** (if no DNS entry) or configure your DNS to point `app.example.com` to your server's IP.
7.  **Open a web browser** and navigate to `http://app.example.com`. NGINX will now proxy requests to your Node.js application.

---

## 🛡️ 7. Basic Security Measures

Implement fundamental security practices for your NGINX server.

### 7.1. Remove Default NGINX Page

The default `default` server block often serves a basic NGINX page. It's good practice to disable or remove it once your own sites are configured.

### Command

```bash
sudo rm /etc/nginx/sites-enabled/default
```
Then `sudo systemctl reload nginx`.

### 7.2. Setting Up Firewall (UFW)

Ensure only necessary ports are open to the internet.

### Commands (for Ubuntu/Debian)

```bash
sudo apt install ufw # Install UFW if not already
sudo ufw allow 'Nginx HTTP' # Allow traffic on port 80
sudo ufw allow 'Nginx HTTPS' # Allow traffic on port 443 (for later SSL)
sudo ufw allow 'OpenSSH' # Ensure SSH port 22 is open so you don't lock yourself out!
sudo ufw enable # Enable the firewall (will ask for confirmation)
sudo ufw status # Check firewall status
```

### Explanation

* `UFW` (Uncomplicated Firewall) is a user-friendly interface for `iptables`.
* `Nginx HTTP` and `Nginx HTTPS` are pre-defined UFW profiles that open ports 80 and 443 respectively.
* Always ensure you allow SSH before enabling the firewall to prevent locking yourself out.

---

## 🚀 What's Next?

You've built a solid foundation in NGINX basics! To continue your journey and become more proficient, explore these advanced topics:

* **NGINX SSL/TLS Configuration**: Secure your websites with HTTPS.
* **Load Balancing**: Distribute traffic across multiple backend servers.
* **Caching**: Improve performance by caching static and dynamic content.
* **URL Rewrites and Redirects**: Advanced traffic management.
* **NGINX Modules**: Extend NGINX functionality.
* **Advanced Logging**: Customizing log formats and analysis.
* **Security Headers**: Adding headers for better security (e.g., HSTS).

Which of these advanced NGINX features would you like to learn about next?