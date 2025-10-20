#!/bin/bash

# Ubuntu Sunucu Kurulum Scripti
echo "🚀 Ubuntu Sunucu Kurulumu Başlıyor..."

# Sistem güncellemesi
echo "📦 Sistem paketleri güncelleniyor..."
sudo apt update && sudo apt upgrade -y

# Gerekli paketleri yükle
echo "🔧 Gerekli paketler yükleniyor..."
sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    python3 \
    python3-pip \
    docker.io \
    docker-compose \
    htop \
    nano \
    vim

# Docker servisini başlat
echo "🐳 Docker servisi başlatılıyor..."
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Git konfigürasyonu
echo "📝 Git konfigürasyonu..."
echo "Git kullanıcı adınızı girin:"
read -r git_username
echo "Git e-posta adresinizi girin:"
read -r git_email

if [ -n "$git_username" ] && [ -n "$git_email" ]; then
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    echo "✅ Git konfigürasyonu tamamlandı"
else
    echo "⚠️  Git konfigürasyonu atlandı"
fi

# Çalışma dizini oluştur
echo "📁 Çalışma dizini oluşturuluyor..."
mkdir -p ~/email-marketing
cd ~/email-marketing

# Repository'yi clone et
echo "📥 Repository clone ediliyor..."
git clone https://github.com/fusionvoyager/mail-postal-sender.git
cd mail-postal-sender
echo "✅ Repository clone edildi"

# Docker container'ları durdur ve kaldır
echo "🧹 Mevcut Docker container'ları temizleniyor..."
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true
sudo docker system prune -af

# Postal sender'ı build et
echo "🔨 Postal sender Docker image'ı oluşturuluyor..."
sudo docker build -t postal-sender .

# E-posta listesi dosyasını kontrol et
echo "📧 E-posta listesi dosyası kontrol ediliyor..."
if [ -f "email_list.txt" ]; then
    echo "✅ E-posta listesi dosyası bulundu: email_list.txt"
    echo "📊 E-posta sayısı: $(wc -l < email_list.txt)"
else
    echo "❌ E-posta listesi dosyası bulunamadı!"
    echo "Lütfen email_list.txt dosyasını oluşturun"
    exit 1
fi

# HTML şablonu oluştur
echo "📄 HTML şablonu oluşturuluyor..."
cat > email_template.html << 'EOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Özel Teklif</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #007bff; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .footer { background: #333; color: white; padding: 10px; text-align: center; font-size: 12px; }
        .button { background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Özel Teklif</h1>
        </div>
        <div class="content">
            <h2>Merhaba {{name}}!</h2>
            <p>Size özel bir teklifimiz var. Bu fırsatı kaçırmayın!</p>
            <p>Detaylar için aşağıdaki butona tıklayın:</p>
            <a href="https://baseprise.com" class="button">Teklifi Görüntüle</a>
            <p>Teşekkürler,<br>Baseprise Ekibi</p>
        </div>
        <div class="footer">
            <p>Bu e-posta {{email}} adresine gönderilmiştir.</p>
            <p>© 2024 Baseprise. Tüm hakları saklıdır.</p>
        </div>
    </div>
</body>
</html>
EOF

echo "✅ HTML şablonu oluşturuldu"

# Test çalıştırma
echo "🧪 Test çalıştırması yapılıyor..."
sudo docker run --rm \
    -v $(pwd)/email_list.txt:/app/email_list.txt:ro \
    -v $(pwd)/email_template.html:/app/email_template.html:ro \
    -e TEST_MODE=true \
    -e TEST_EMAIL_LIMIT=3 \
    postal-sender

echo ""
echo "🎉 Kurulum tamamlandı!"
echo ""
echo "📋 Kullanım:"
echo "1. E-posta listenizi düzenleyin: nano email_list.txt"
echo "2. HTML şablonunu düzenleyin: nano email_template.html"
echo "3. Test çalıştırın: ./test_run.sh"
echo "4. Production çalıştırın: ./production_run.sh"
echo ""
echo "🔧 Konfigürasyon:"
echo "- Postal sunucu URL: https://postal.baseprise.com"
echo "- API Key: FEHHDaTdL2yVaawPDoGaIww7"
echo "- Test modu: TEST_MODE=true"
echo "- Production modu: TEST_MODE=false"
echo ""
echo "📊 Mevcut e-posta sayısı: $(wc -l < email_list.txt)"
