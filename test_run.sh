#!/bin/bash

# Test Çalıştırma Scripti
echo "🧪 Test Modunda E-posta Gönderimi Başlıyor..."

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

# Docker container'ı çalıştır (test modunda)
echo "🐳 Docker container başlatılıyor (Test modu)..."
echo "📧 Sadece 5 e-posta gönderilecek"
echo ""

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
    -e TEST_EMAIL_LIMIT=5 \
    -e BATCH_SIZE=5 \
    -e DELAY_BETWEEN_BATCHES=2 \
    -e DELAY_BETWEEN_EMAILS=0.5 \
    postal-sender

echo ""
echo "✅ Test tamamlandı!"
echo "📊 Logları görüntülemek için: cat logs/email_sending.log"
echo "📋 Production çalıştırmak için: ./production_run.sh"
