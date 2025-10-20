#!/bin/bash

# Production Çalıştırma Scripti
echo "🚀 Production Modunda E-posta Gönderimi Başlıyor..."

# E-posta listesi dosyasını kontrol et
if [ ! -f "email_list.txt" ] && [ ! -f "email_list.csv" ]; then
    echo "❌ E-posta listesi dosyası bulunamadı!"
    echo "Lütfen email_list.txt veya email_list.csv dosyasını oluşturun"
    exit 1
fi

# HTML şablonunu kontrol et
if [ ! -f "email_template.html" ]; then
    echo "❌ HTML şablonu bulunamadı!"
    echo "Lütfen email_template.html dosyasını oluşturun"
    exit 1
fi

# E-posta sayısını kontrol et
email_count=0
if [ -f "email_list.txt" ]; then
    email_count=$(wc -l < email_list.txt)
elif [ -f "email_list.csv" ]; then
    email_count=$(wc -l < email_list.csv)
fi

echo "📧 Toplam $email_count e-posta gönderilecek"
echo "⚠️  Bu işlem yaklaşık $((email_count / 50 * 5 / 60)) dakika sürecek"
echo ""

# Onay iste
read -p "Devam etmek istiyor musunuz? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ İşlem iptal edildi"
    exit 1
fi

# Docker container'ı çalıştır (production modunda)
echo "🐳 Docker container başlatılıyor (Production modu)..."
echo ""

sudo docker run --rm \
    -v $(pwd)/email_list.txt:/app/email_list.txt:ro \
    -v $(pwd)/email_template.html:/app/email_template.html:ro \
    -v $(pwd)/logs:/app/logs \
    -e POSTAL_SERVER_URL=https://postal.baseprise.com \
    -e POSTAL_API_KEY=FEHHDaTdL2yVaawPDoGaIww7 \
    -e SENDER_EMAIL=noreply@baseprise.com \
    -e SENDER_NAME="Baseprise Marketing" \
    -e EMAIL_SUBJECT="Özel Teklif - Baseprise" \
    -e TEST_MODE=false \
    -e BATCH_SIZE=50 \
    -e DELAY_BETWEEN_BATCHES=5 \
    -e DELAY_BETWEEN_EMAILS=0.1 \
    postal-sender

echo ""
echo "🎉 Production gönderimi tamamlandı!"
echo "📊 Logları görüntülemek için: cat logs/email_sending.log"
echo "📈 İstatistikler için: grep 'Gönderildi' logs/email_sending.log | wc -l"
