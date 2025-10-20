#!/usr/bin/env python3
"""
Postal E-posta Gönderim Sistemi
Docker container içinde çalışacak Python script'i
"""

import requests
import json
import csv
import time
import logging
from datetime import datetime
from typing import List, Dict, Optional
import os
import sys
from pathlib import Path

# Logging ayarları
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('email_sending.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class PostalEmailSender:
    def __init__(self, server_url: str, api_key: str):
        """
        Postal E-posta Gönderici sınıfı
        
        Args:
            server_url: Postal sunucu URL'i (örn: https://postal.baseprise.com)
            api_key: Postal API anahtarı
        """
        self.server_url = server_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers.update({
            'X-Server-API-Key': api_key,
            'Content-Type': 'application/json'
        })
        
    def send_email(self, to_email: str, subject: str, html_content: str, 
                   from_email: str, from_name: str = None) -> Dict:
        """
        Tek e-posta gönder
        
        Args:
            to_email: Alıcı e-posta adresi
            subject: E-posta konusu
            html_content: HTML içerik
            from_email: Gönderen e-posta adresi
            from_name: Gönderen adı (opsiyonel)
            
        Returns:
            API yanıtı
        """
        url = f"{self.server_url}/api/v1/send/message"
        
        payload = {
            "to": [to_email],
            "from": from_email,
            "subject": subject,
            "html_body": html_content,
            "plain_body": self._html_to_text(html_content)
        }
        
        if from_name:
            payload["from_name"] = from_name
            
        try:
            # Debug: HTML içeriğini logla
            logger.info(f"HTML içeriği uzunluğu: {len(html_content)} karakter")
            logger.info(f"HTML içeriği başlangıcı: {html_content[:100]}...")
            
            response = self.session.post(url, json=payload, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"E-posta gönderim hatası ({to_email}): {e}")
            return {"error": str(e)}
    
    def send_batch_emails(self, email_list: List[Dict], subject: str, 
                          html_content: str, from_email: str, 
                          from_name: str = None, delay: float = 0.1) -> Dict:
        """
        Toplu e-posta gönder
        
        Args:
            email_list: E-posta listesi [{"email": "test@example.com", "name": "Test"}]
            subject: E-posta konusu
            html_content: HTML içerik
            from_email: Gönderen e-posta adresi
            from_name: Gönderen adı (opsiyonel)
            delay: E-postalar arası bekleme süresi (saniye)
            
        Returns:
            Gönderim istatistikleri
        """
        results = {
            "success": 0,
            "failed": 0,
            "errors": []
        }
        
        logger.info(f"Toplu e-posta gönderimi başlıyor: {len(email_list)} e-posta")
        
        for i, email_data in enumerate(email_list):
            try:
                to_email = email_data.get('email', '')
                if not to_email:
                    logger.warning(f"Geçersiz e-posta adresi: {email_data}")
                    results["failed"] += 1
                    continue
                
                # Kişiselleştirilmiş içerik oluştur
                personalized_content = self._personalize_content(html_content, email_data)
                
                # E-posta gönder
                response = self.send_email(
                    to_email=to_email,
                    subject=subject,
                    html_content=personalized_content,
                    from_email=from_email,
                    from_name=from_name
                )
                
                if "error" in response:
                    results["failed"] += 1
                    results["errors"].append(f"{to_email}: {response['error']}")
                    logger.error(f"Gönderim hatası: {to_email}")
                else:
                    results["success"] += 1
                    logger.info(f"✅ Gönderildi: {to_email} ({i+1}/{len(email_list)})")
                
                # Rate limiting
                if delay > 0:
                    time.sleep(delay)
                    
            except Exception as e:
                results["failed"] += 1
                results["errors"].append(f"{email_data}: {str(e)}")
                logger.error(f"Beklenmeyen hata: {e}")
        
        logger.info(f"Toplu gönderim tamamlandı: {results['success']} başarılı, {results['failed']} başarısız")
        return results
    
    def _html_to_text(self, html_content: str) -> str:
        """HTML içeriği düz metne çevir"""
        import re
        # Basit HTML tag'lerini kaldır
        text = re.sub(r'<[^>]+>', '', html_content)
        # Fazla boşlukları temizle
        text = re.sub(r'\s+', ' ', text)
        return text.strip()
    
    def _personalize_content(self, html_content: str, email_data: Dict) -> str:
        """İçeriği kişiselleştir"""
        content = html_content
        
        # E-posta adresinden isim çıkar
        email = email_data.get('email', '')
        name = email_data.get('name', '')
        
        if not name and '@' in email:
            name = email.split('@')[0].replace('.', ' ').title()
        
        # Placeholder'ları değiştir
        content = content.replace('{{name}}', name or 'Değerli Müşterimiz')
        content = content.replace('{{email}}', email)
        content = content.replace('{{first_name}}', name.split()[0] if name else 'Değerli')
        
        return content

def load_email_list(file_path: str) -> List[Dict]:
    """TXT veya CSV dosyasından e-posta listesi yükle"""
    email_list = []
    
    try:
        # Dosya uzantısını kontrol et
        if file_path.endswith('.txt'):
            # TXT dosyası - her satırda bir e-posta
            with open(file_path, 'r', encoding='utf-8') as file:
                for line_num, line in enumerate(file, 1):
                    email = line.strip()
                    if email and '@' in email:
                        # E-posta adresinden isim çıkar
                        name = email.split('@')[0].replace('.', ' ').title()
                        email_list.append({
                            'email': email,
                            'name': name
                        })
                    elif email:  # Boş olmayan ama geçersiz e-posta
                        logger.warning(f"Satır {line_num}: Geçersiz e-posta formatı: {email}")
        
        elif file_path.endswith('.csv'):
            # CSV dosyası - sütunlu format
            with open(file_path, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    # Farklı sütun isimlerini dene
                    email = row.get('email') or row.get('Email') or row.get('E-posta') or row.get('e-posta')
                    name = row.get('name') or row.get('Name') or row.get('İsim') or row.get('isim')
                    
                    if email and '@' in email:
                        email_list.append({
                            'email': email.strip(),
                            'name': name.strip() if name else email.split('@')[0].replace('.', ' ').title()
                        })
                    elif email:  # Geçersiz e-posta
                        logger.warning(f"Geçersiz e-posta formatı: {email}")
        
        else:
            logger.error(f"Desteklenmeyen dosya formatı: {file_path}")
            return []
        
        logger.info(f"E-posta listesi yüklendi: {len(email_list)} adet")
        return email_list
        
    except FileNotFoundError:
        logger.error(f"Dosya bulunamadı: {file_path}")
        return []
    except Exception as e:
        logger.error(f"Dosya okuma hatası: {e}")
        return []

def load_html_template(template_file: str) -> str:
    """HTML şablonu yükle"""
    try:
        with open(template_file, 'r', encoding='utf-8') as file:
            content = file.read()
        logger.info(f"HTML şablonu yüklendi: {template_file}")
        return content
    except FileNotFoundError:
        logger.error(f"HTML şablonu bulunamadı: {template_file}")
        return ""
    except Exception as e:
        logger.error(f"HTML şablonu okuma hatası: {e}")
        return ""

def main():
    """Ana fonksiyon"""
    # Konfigürasyon
    POSTAL_SERVER_URL = os.getenv('POSTAL_SERVER_URL', 'https://postal.baseprise.com')
    POSTAL_API_KEY = os.getenv('POSTAL_API_KEY', 'FEHHDaTdL2yVaawPDoGaIww7')
    SENDER_EMAIL = os.getenv('SENDER_EMAIL', 'noreply@baseprise.com')
    SENDER_NAME = os.getenv('SENDER_NAME', 'Baseprise Marketing')
    EMAIL_LIST_FILE = os.getenv('EMAIL_LIST_FILE', 'email_list.csv')
    HTML_TEMPLATE_FILE = os.getenv('HTML_TEMPLATE_FILE', 'email_template.html')
    SUBJECT = os.getenv('EMAIL_SUBJECT', 'Özel Teklif - Baseprise')
    BATCH_SIZE = int(os.getenv('BATCH_SIZE', '50'))
    DELAY_BETWEEN_BATCHES = int(os.getenv('DELAY_BETWEEN_BATCHES', '5'))
    DELAY_BETWEEN_EMAILS = float(os.getenv('DELAY_BETWEEN_EMAILS', '0.1'))
    TEST_MODE = os.getenv('TEST_MODE', 'false').lower() == 'true'
    TEST_EMAIL_LIMIT = int(os.getenv('TEST_EMAIL_LIMIT', '10'))
    
    logger.info("🚀 Postal E-posta Gönderim Sistemi Başlatılıyor")
    logger.info(f"Sunucu: {POSTAL_SERVER_URL}")
    logger.info(f"Gönderen: {SENDER_EMAIL}")
    
    # E-posta listesi dosyasını bul
    email_list_file = None
    if os.path.exists(EMAIL_LIST_FILE):
        email_list_file = EMAIL_LIST_FILE
    elif os.path.exists('email_list.txt'):
        email_list_file = 'email_list.txt'
    elif os.path.exists('email_list.csv'):
        email_list_file = 'email_list.csv'
    else:
        logger.error("E-posta listesi dosyası bulunamadı! (email_list.txt veya email_list.csv)")
        return
    
    # E-posta listesini yükle
    email_list = load_email_list(email_list_file)
    if not email_list:
        logger.error("E-posta listesi yüklenemedi!")
        return
    
    # Test modu kontrolü
    if TEST_MODE:
        email_list = email_list[:TEST_EMAIL_LIMIT]
        logger.info(f"🧪 Test modu: Sadece {len(email_list)} e-posta gönderilecek")
    
    # HTML şablonunu yükle
    html_content = load_html_template(HTML_TEMPLATE_FILE)
    if not html_content:
        logger.error("HTML şablonu yüklenemedi!")
        return
    
    # Postal sender oluştur
    sender = PostalEmailSender(POSTAL_SERVER_URL, POSTAL_API_KEY)
    
    # Toplu gönderim
    total_emails = len(email_list)
    logger.info(f"📧 Toplam {total_emails} e-posta gönderilecek")
    
    # Batch'ler halinde gönder
    for i in range(0, total_emails, BATCH_SIZE):
        batch = email_list[i:i + BATCH_SIZE]
        batch_num = (i // BATCH_SIZE) + 1
        total_batches = (total_emails + BATCH_SIZE - 1) // BATCH_SIZE
        
        logger.info(f"📦 Batch {batch_num}/{total_batches} işleniyor ({len(batch)} e-posta)")
        
        # Batch'i gönder
        results = sender.send_batch_emails(
            email_list=batch,
            subject=SUBJECT,
            html_content=html_content,
            from_email=SENDER_EMAIL,
            from_name=SENDER_NAME,
            delay=DELAY_BETWEEN_EMAILS
        )
        
        logger.info(f"✅ Batch {batch_num} tamamlandı: {results['success']} başarılı, {results['failed']} başarısız")
        
        # Son batch değilse bekle
        if i + BATCH_SIZE < total_emails:
            logger.info(f"⏳ {DELAY_BETWEEN_BATCHES} saniye bekleniyor...")
            time.sleep(DELAY_BETWEEN_BATCHES)
    
    logger.info("🎉 Tüm e-postalar gönderildi!")

if __name__ == "__main__":
    main()
