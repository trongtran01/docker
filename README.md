# Cài đặt Docker để chạy dự án Laravel trên Windows (WSL2) và Ubuntu

## Giới thiệu

Tài liệu hướng dẫn cài đặt môi trường Docker và chạy dự án Laravel (`goods_shop`) trên Windows bằng **WSL2 (Ubuntu)**. Trên Ubuntu thật, làm tương tự từ Bước 2.

**Công nghệ sử dụng:**
- PHP 8.2 (PHP-FPM) / Laravel
- Docker Engine + Docker Compose v2
- MySQL 8.0
- Nginx
- Redis, Mailpit, phpMyAdmin

## Yêu cầu hệ thống

- Windows 10 (bản 2004 trở lên) hoặc Windows 11
- Bật ảo hóa (Virtualization) trong BIOS
- Git
- Docker Engine chạy **bên trong WSL2** (không cần Docker Desktop)
- Source code dự án Laravel

## Cấu trúc thư mục

```
goods_shop/
├── docker/
│   ├── docker-compose.linux.yml     # Dùng cho WSL2 và Ubuntu
│   ├── docker-compose.windows.yml   # Chỉ dùng nếu chạy Docker Desktop từ PowerShell
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── switch-os.sh
│   ├── .env.example
│   ├── nginx/default.conf
│   └── php/php.ini
└── src/                             # Source code Laravel
```

> **Quan trọng:** đặt dự án trong hệ file của WSL (`~/projects/...`), **không** đặt trên ổ `C:\` (`/mnt/c/...`). Đặt trên `C:\` sẽ chậm và hay lỗi symlink/quyền file.

---

## Windows (WSL2)

### Bước 1: Cài đặt WSL2 và Ubuntu

**1. Mở PowerShell với quyền Administrator**

- Nhấn `Windows`, tìm `PowerShell`.
- Nhấn chuột phải vào **Windows PowerShell** → chọn **Run as administrator**.
- Chọn **Yes** nếu được yêu cầu xác nhận.

**2. Cài đặt WSL2 và Ubuntu**

Chạy lệnh sau trong PowerShell:

```powershell
wsl --install -d Ubuntu
```

Chờ cài đặt hoàn tất và khởi động lại máy tính nếu được yêu cầu.

**3. Khởi tạo Ubuntu**

- Mở menu Start, tìm và mở ứng dụng `Ubuntu`.
- Nhập username và password theo hướng dẫn trên màn hình.
- Lưu ý: Khi nhập password, màn hình không hiển thị ký tự. Đây là bình thường.

**4. Kiểm tra cài đặt**

Mở PowerShell và chạy lệnh:

```powershell
wsl -l -v
```

Kiểm tra kết quả: Ubuntu phải xuất hiện trong danh sách và cột `VERSION` phải là `2`.

Nếu đúng, bạn đã hoàn thành bước cài đặt WSL2 và Ubuntu.

### Bước 2: Cài Docker Engine trong Ubuntu (WSL)

Mở terminal **Ubuntu** và chạy:

```bash
sudo apt update
sudo apt install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

Đóng terminal, mở lại Ubuntu rồi kiểm tra:

```bash
docker version
docker compose version
```

Phải thấy cả **Client** và **Server**. Nếu `Server` báo không kết nối được:

```bash
sudo service docker start
```

> Nếu gặp lỗi `client version 1.43 is too old. Minimum supported API version is 1.44`, nghĩa là Docker Compose quá cũ. Cài bản mới: `sudo apt install -y docker-compose-v2`, và nếu vẫn dùng bản cũ thì đổi tên plugin cũ: `sudo mv /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose.old`.

### Bước 3: Cho Docker tự chạy khi mở WSL

```bash
sudo tee /etc/wsl.conf > /dev/null <<'EOF'
[boot]
systemd=true
EOF
```

Trong **PowerShell** chạy `wsl --shutdown`, mở lại Ubuntu rồi:

```bash
sudo systemctl enable docker
```

### Bước 4: Lấy source code vào WSL

Trong terminal Ubuntu:

```bash
mkdir -p ~/projects
cd ~/projects
git clone <url-repo> goods_shop
cd goods_shop
```

Đường dẫn để mở thư mục từ Windows (File Explorer):

```
\\wsl.localhost\Ubuntu\home\inth\projects\goods_shop
```

(Thay `inth` bằng username Ubuntu của bạn.) Mở bằng VS Code từ WSL:

```bash
code .
```

Góc dưới bên trái phải hiện `WSL: Ubuntu`. Khi sửa file `.sh`, `Dockerfile`, `.conf`, `.ini`, đảm bảo kiểu xuống dòng là **LF** (không phải CRLF).

### Bước 5: Tạo file `.env` cho Docker

```bash
cd ~/projects/goods_shop/docker
cat > .env <<'EOF'
STRIPE_SECRET_KEY=
PAYPAL_CLIENT_ID=
PAYPAL_CLIENT_SECRET=
HOST_UID=1000
HOST_GID=1000
COMPOSE_FILE=docker-compose.linux.yml
EOF
```

- Điền các key thật vào `.env` (không commit file này).
- `HOST_UID`/`HOST_GID` phải khớp kết quả của `id -u` và `id -g`.
- `COMPOSE_FILE` giúp chạy `docker compose` mà không cần `-f`.

Hoặc dùng script tự động: `chmod +x switch-os.sh && ./switch-os.sh` (giữ file compose của hệ điều hành đang dùng, đổi file còn lại thành `.bak`).

### Bước 6: Cấu hình Laravel

Sửa `src/.env` (tạo từ `.env.example` nếu chưa có):

```dotenv
APP_URL=http://localhost:8080

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret

REDIS_HOST=redis
MAIL_HOST=mailpit
MAIL_PORT=1025
```

> Các container gọi nhau bằng **tên service** (`db`, `redis`, `mailpit`), không dùng `127.0.0.1`. Dùng `127.0.0.1` sẽ gặp lỗi `SQLSTATE[HY000] [2002] Connection refused`.

### Bước 7: Build và chạy

```bash
cd ~/projects/goods_shop/docker
docker compose up -d --build
docker compose ps
```

Lần đầu `entrypoint.sh` tự chạy `composer install` và tạo `APP_KEY`, mất vài phút. Theo dõi:

```bash
docker compose logs -f app
```

Khi thấy `ready to handle connections` là xong. Trong lúc chờ, truy cập web sẽ báo `502 Bad Gateway`, đây là bình thường.

### Bước 8: Tạo bảng dữ liệu

```bash
docker compose exec app php artisan config:clear
docker compose exec app php artisan migrate
```

Nếu có file SQL backup:

```bash
docker compose exec -T db mysql -uroot -proot laravel < backup.sql
```

### Bước 9: Cấp quyền cho thư mục ảnh

Chạy ở thư mục `docker`:

```bash
docker compose exec app chmod 755 /var/www/storage/app/public/banner
```

Nếu vẫn không ghi được file, cấp quyền từ WSL:

```bash
sudo chown -R $(id -u):$(id -g) ~/projects/goods_shop/src/storage ~/projects/goods_shop/src/bootstrap/cache
```

Ảnh upload cũ cần được đặt vào đúng thư mục:

```
\\wsl.localhost\Ubuntu\home\inth\projects\goods_shop\src\storage\app\public
```

(ví dụ `banner/`, `products/`...). Tên file phải khớp với tên lưu trong database, nếu không ảnh sẽ báo `404 Not Found`.

### Bước 10: Truy cập

| Dịch vụ | Địa chỉ |
|---|---|
| Website | http://localhost:8080 |
| phpMyAdmin | http://localhost:8081 (server `db`, user `laravel`, pass `secret`) |
| Mailpit | http://localhost:8025 |
| MySQL (từ máy host) | `127.0.0.1:3307` |

---

## Lệnh thường dùng

Luôn chạy trong terminal **Ubuntu**, thư mục `~/projects/goods_shop/docker`:

```bash
docker compose up -d              # Chạy
docker compose down               # Dừng và xóa container
docker compose restart web        # Khởi động lại nginx
docker compose logs -f app        # Xem log PHP
docker compose exec app bash      # Vào container app
docker compose exec app php artisan <lệnh>
docker compose exec app composer <lệnh>
```

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân / Cách xử lý |
|---|---|
| `no configuration file provided: not found` | Thiếu `COMPOSE_FILE` trong `docker/.env`, hoặc đang đứng sai thư mục. Chạy với `-f docker-compose.linux.yml` |
| `Cannot connect to the Docker daemon` | Docker chưa chạy: `sudo service docker start` |
| `client version 1.43 is too old` | Docker Compose quá cũ, xem ghi chú ở Bước 2 |
| `502 Bad Gateway` | `app` chưa chạy xong `composer install`. Đợi, xem `docker compose logs -f app`, rồi `docker compose restart web` |
| `File not found.` | Thư mục `src/` trống hoặc sai cấp, `src/public/index.php` phải tồn tại |
| `SQLSTATE[HY000] [2002] Connection refused` | `DB_HOST` đang là `127.0.0.1`, đổi thành `db` rồi `php artisan config:clear` |
| Container `web` thoát ngay | Xem `docker compose logs web`, thường là lỗi cú pháp `nginx/default.conf` |
| Ảnh `404 Not Found` | File ảnh chưa có trong `src/storage/app/public/...` hoặc tên khác với database |
| `bad interpreter: /bin/sh^M` | `entrypoint.sh` bị CRLF. Chuyển về LF trong VS Code, hoặc `sed -i 's/\r$//' entrypoint.sh` |

## Lưu ý

- Chỉ chạy `docker compose` trong WSL, không chạy từ PowerShell (trừ khi dùng Docker Desktop với `docker-compose.windows.yml`).
- Không bật đồng thời Docker Desktop (WSL Integration) và Docker Engine trong Ubuntu, vì hai bên tranh nhau `docker.sock`.
- Không commit `.env`, `test-card.txt` và các key (Stripe, PayPal). Nếu lỡ lộ key, hãy tạo lại key mới.
