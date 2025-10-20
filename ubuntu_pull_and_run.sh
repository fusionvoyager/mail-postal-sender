#!/bin/bash

# Ubuntu Sunucu - Pull ve Çalıştırma Scripti
echo "🚀 Ubuntu Sunucu - Postal E-posta Gönderim Sistemi"

# Sistem güncellemesi
echo "📦 Sistem paketleri güncelleniyor..."
sudo apt update

# Gerekli paketleri yükle (eğer yoksa)
echo "🔧 Gerekli paketler kontrol ediliyor..."
sudo apt install -y git docker.io python3 python3-pip

# Docker servisini başlat
echo "🐳 Docker servisi başlatılıyor..."
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Çalışma dizini oluştur
echo "📁 Çalışma dizini oluşturuluyor..."
mkdir -p ~/email-marketing
cd ~/email-marketing

# Repository'yi clone et veya güncelle
if [ -d "mail-postal-sender" ]; then
    echo "📥 Repository güncelleniyor..."
    cd mail-postal-sender
    git pull origin main
else
    echo "📥 Repository clone ediliyor..."
    git clone https://github.com/fusionvoyager/mail-postal-sender.git
    cd mail-postal-sender
fi

# Docker container'ları temizle
echo "🧹 Mevcut Docker container'ları temizleniyor..."
sudo docker stop $(sudo docker ps -q) 2>/dev/null || true
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true
sudo docker system prune -af

# Postal sender'ı build et
echo "🔨 Postal sender Docker image'ı oluşturuluyor..."
sudo docker build -t postal-sender .

# E-posta listesi dosyasını kontrol et
echo "📧 E-posta listesi dosyası kontrol ediliyor..."
if [ -f "email_list.txt" ]; then
    email_count=$(wc -l < email_list.txt)
    echo "✅ E-posta listesi bulundu: $email_count e-posta"
else
    echo "❌ E-posta listesi dosyası bulunamadı!"
    echo "Lütfen email_list.txt dosyasını oluşturun"
    exit 1
fi

# HTML şablonu oluştur (eğer yoksa)
if [ ! -f "email_template.html" ]; then
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
fi

# Test çalıştırma
echo "🧪 Test çalıştırması yapılıyor..."
sudo docker run --rm \
    -v $(pwd)/email_list.txt:/app/email_list.txt:ro \
    -v $(pwd)/email_template.html:/app/email_template.html:ro \
    -v $(pwd)/logs:/app/logs \
    -e POSTAL_SERVER_URL=https://postal.baseprise.com \
    -e POSTAL_API_KEY=FEHHDaTdL2yVaawPDoGaIww7 \
    -e SENDER_EMAIL=noreply@baseprise.com \
    -e SENDER_NAME="Baseprise Marketing" \
    -e EMAIL_SUBJECT="Test E-posta - Baseprise" \
    -e TEST_MODE=true \
    -e TEST_EMAIL_LIMIT=3 \
    -e BATCH_SIZE=3 \
    -e DELAY_BETWEEN_BATCHES=1 \
    -e DELAY_BETWEEN_EMAILS=0.5 \
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
echo ""
echo "🚀 Hızlı başlangıç:"
echo "git pull origin main  # Güncellemeleri çek"
echo "./test_run.sh        # Test çalıştır"
echo "./production_run.sh  # Production çalıştır"
