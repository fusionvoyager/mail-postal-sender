#!/bin/bash

# Git Repository Push Scripti
echo "🚀 Git Repository'ye Push İşlemi Başlıyor..."

# Git repository'sini başlat (eğer yoksa)
if [ ! -d ".git" ]; then
    echo "📁 Git repository başlatılıyor..."
    git init
    git branch -M main
fi

# .gitignore dosyası oluştur
echo "📄 .gitignore dosyası oluşturuluyor..."
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
env.bak/
venv.bak/

# Logs
*.log
logs/
email_sending.log

# Data files
data/

# Docker
.dockerignore

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Temporary files
*.tmp
*.temp
EOF

# Dosyaları ekle
echo "📦 Dosyalar ekleniyor..."
git add .

# Commit yap
echo "💾 Commit yapılıyor..."
git commit -m "Postal E-posta Gönderim Sistemi - İlk versiyon

- Python tabanlı e-posta gönderim sistemi
- Postal API entegrasyonu
- Docker container desteği
- TXT ve CSV dosya desteği
- Batch işleme ve rate limiting
- Test modu desteği"

# Remote repository ekle
echo "🔗 Remote repository ekleniyor..."
git remote add origin https://github.com/fusionvoyager/mail-postal-sender.git
echo "✅ Remote repository eklendi"

# Push yap
echo "⬆️  Push yapılıyor..."
git push -u origin main

echo "✅ Git push işlemi tamamlandı!"
echo ""
echo "📋 Sonraki adımlar:"
echo "1. Ubuntu sunucuya bağlanın"
echo "2. git clone https://github.com/fusionvoyager/mail-postal-sender.git"
echo "3. cd mail-postal-sender"
echo "4. ./ubuntu_setup.sh"
echo "5. E-posta listenizi düzenleyin: nano email_list.txt"
echo "6. Test çalıştırın: ./test_run.sh"
echo "7. Production çalıştırın: ./production_run.sh"
