# Postal E-posta Gönderim Sistemi

Docker container içinde çalışan, Postal API'sini kullanarak toplu e-posta gönderimi yapan Python sistemi.

## 🚀 Özellikler

- **Postal API Entegrasyonu**: Postal sunucu API'si ile tam entegrasyon
- **Toplu E-posta Gönderimi**: 5,000+ e-posta gönderimi desteği
- **Batch İşleme**: Performans için batch'ler halinde gönderim
- **Rate Limiting**: Sunucu yükünü azaltmak için hız sınırlaması
- **Kişiselleştirme**: E-posta içeriğinde kişiselleştirme desteği
- **Test Modu**: Güvenli test gönderimi
- **Detaylı Loglama**: Tüm işlemler için kapsamlı loglama
- **Docker Desteği**: Kolay kurulum ve dağıtım

## 📋 Gereksinimler

- Docker ve Docker Compose
- Ubuntu sunucu (Postal kurulu)
- Python 3.11+ (Docker container içinde)

## 🛠️ Kurulum

### 1. Dosyaları İndirin
```bash
git clone <repository-url>
cd postal-sender
```

### 2. Kurulum Scriptini Çalıştırın
```bash
chmod +x setup.sh
./setup.sh
```

### 3. E-posta Listesini Hazırlayın
`email_list.csv` dosyasını düzenleyin:
```csv
email,name
user1@example.com,Kullanıcı 1
user2@example.com,Kullanıcı 2
```

### 4. HTML Şablonunu Düzenleyin
`email_template.html` dosyasını düzenleyin. Kişiselleştirme için:
- `{{name}}`: Kullanıcı adı
- `{{email}}`: E-posta adresi
- `{{first_name}}`: İlk isim

## 🚀 Kullanım

### Test Modu (Güvenli)
```bash
docker run --rm \
    -v $(pwd)/email_list.csv:/app/email_list.csv:ro \
    -v $(pwd)/email_template.html:/app/email_template.html:ro \
    -e TEST_MODE=true \
    -e TEST_EMAIL_LIMIT=5 \
    postal-sender
```

### Production Modu
```bash
docker-compose up -d
```

### Logları İzleme
```bash
docker logs -f postal-email-sender
```

## ⚙️ Konfigürasyon

Environment değişkenleri ile yapılandırma:

```bash
# Postal Sunucu Ayarları
POSTAL_SERVER_URL=https://postal.baseprise.com
POSTAL_API_KEY=your_api_key_here

# E-posta Ayarları
SENDER_EMAIL=noreply@baseprise.com
SENDER_NAME=Baseprise Marketing
EMAIL_SUBJECT=Özel Teklif - Baseprise

# Gönderim Ayarları
BATCH_SIZE=50                    # Her batch'te kaç e-posta
DELAY_BETWEEN_BATCHES=5          # Batch'ler arası bekleme (saniye)
DELAY_BETWEEN_EMAILS=0.1         # E-postalar arası bekleme (saniye)

# Test Ayarları
TEST_MODE=false                  # Test modu
TEST_EMAIL_LIMIT=10              # Test modunda kaç e-posta gönderilecek
```

## 📊 Performans

- **Batch Size**: 50 e-posta/batch (önerilen)
- **Rate Limiting**: 0.1 saniye/e-posta
- **Batch Delay**: 5 saniye/batch
- **5,000 E-posta**: ~15-20 dakika

## 🔧 Troubleshooting

### Container Çalışmıyor
```bash
docker logs postal-email-sender
```

### E-posta Gönderilmiyor
1. API anahtarını kontrol edin
2. Postal sunucu erişimini kontrol edin
3. Log dosyalarını inceleyin

### Performans Sorunları
- `BATCH_SIZE` değerini azaltın
- `DELAY_BETWEEN_EMAILS` değerini artırın

## 📁 Dosya Yapısı

```
postal-sender/
├── postal_sender.py      # Ana Python script
├── config.py            # Konfigürasyon
├── requirements.txt     # Python bağımlılıkları
├── Dockerfile          # Docker image tanımı
├── docker-compose.yml  # Docker Compose yapılandırması
├── setup.sh           # Kurulum scripti
├── email_list.csv     # E-posta listesi
├── email_template.html # HTML şablonu
└── README.md          # Bu dosya
```

## 🛡️ Güvenlik

- API anahtarları environment değişkenlerinde saklanır
- Test modu ile güvenli test gönderimi
- Rate limiting ile sunucu koruması
- Detaylı hata loglama

## 📈 Monitoring

Log dosyaları:
- `email_sending.log`: Detaylı gönderim logları
- Docker logs: Container logları

## 🤝 Destek

Sorunlar için:
1. Log dosyalarını kontrol edin
2. Docker container durumunu kontrol edin
3. Postal sunucu bağlantısını test edin
