# TaaOS AI Kullanım Kılavuzu

## Giriş

TaaOS AI, işletim sisteminizle doğal dil kullanarak konuşmanızı sağlayan gelişmiş bir yapay zeka asistanıdır. Türkçe ve İngilizce komutları anlayabilir ve size yardımcı olabilir.

## Temel Kullanım

### Doğal Dil ile Komut

En basit kullanım şekli, istediğinizi doğal dil ile yazmaktır:

```bash
taaos "bir web scraper oluştur"
taaos "bu kodu incele: myfile.py"
taaos "sistemdeki hataları göster"
```

### Klasik Komut Yapısı

Daha spesifik olmak isterseniz:

```bash
taaos generate "REST API with authentication" python
taaos review mycode.py
taaos test utils.py
```

## Özellikler

### 1. Kod Oluşturma

**Kullanım:**
```bash
taaos "Python ile web scraper yap"
taaos generate "authentication system" python
```

**Ne yapar:**
- Doğal dilden kod üretir
- Best practice'leri uygular
- Error handling ekler
- Örnek kullanım gösterir

### 2. Kod İnceleme

**Kullanım:**
```bash
taaos "app.py dosyasını incele"
taaos review mycode.py python
```

**Ne yapar:**
- Güvenlik açıklarını bulur
- Performans sorunlarını tespit eder
- Best practice ihlallerini gösterir
- Refactoring önerileri sunar

### 3. Test Oluşturma

**Kullanım:**
```bash
taaos "utils.py için test yaz"
taaos test mycode.py
```

**Ne yapar:**
- Otomatik unit test oluşturur
- Edge case'leri kapsar
- Mock'ları ekler
- Test framework'üne uygun kod üretir

### 4. Hata Açıklama

**Kullanım:**
```bash
taaos "bu hatayı açıkla: NameError"
taaos explain "TypeError: cannot concatenate str and int"
```

**Ne yapar:**
- Hatanın nedenini açıklar
- Nasıl düzeltileceğini gösterir
- Gelecekte nasıl önleneceğini anlatır
- Çözüm kodu verir

### 5. Dokümantasyon

**Kullanım:**
```bash
taaos "functions.py için dokümantasyon yaz"
taaos document mycode.py
```

**Ne yapar:**
- Kapsamlı docstring oluşturur
- Parametreleri açıklar
- Örnekler ekler
- Return değerlerini dokümante eder

## İleri Seviye Özellikler

### Kod Çevirisi

Kodu bir dilden diğerine çevirin:

```bash
taaos translate script.py python javascript
taaos "bu Python kodunu Rust'a çevir: app.py"
```

### Mimari Önerileri

Sistem mimarisi için öneri alın:

```bash
taaos architecture "e-commerce platform with 1M users"
taaos "blog sitesi için tech stack öner"
```

### Log Analizi

Sistem loglarını analiz edin:

```bash
taaos analyze-logs /var/log/syslog
taaos "son 100 sistem hatasını analiz et"
```

### Sorgu Optimizasyonu

Veritabanı sorgularını optimize edin:

```bash
taaos optimize-query "SELECT * FROM users WHERE age > 18" postgresql
```

## Örnekler

### Web Development

```bash
# React component oluştur
taaos "React ile login formu yap"

# API endpoint yaz
taaos "FastAPI ile user CRUD endpoints oluştur"

# Frontend kodu incele
taaos review components/Header.jsx
```

### Backend Development

```bash
# Database model oluştur
taaos "SQLAlchemy ile User modeli yap"

# API test yaz
taaos test api/routes.py

# Performans optimizasyonu
taaos "bu sorguyu optimize et: SELECT * FROM orders JOIN users"
```

### DevOps

```bash
# Dockerfile oluştur
taaos "Node.js uygulaması için Dockerfile yaz"

# CI/CD pipeline
taaos "GitHub Actions ile test pipeline oluştur"

# Log analizi
taaos analyze-logs /var/log/nginx/error.log
```

### Data Science

```bash
# Data processing
taaos "pandas ile CSV dosyası oku ve analiz et"

# ML model
taaos "scikit-learn ile classification modeli yap"

# Visualization
taaos "matplotlib ile bar chart oluştur"
```

## İpuçları

1. **Türkçe veya İngilizce kullanabilirsiniz**
   ```bash
   taaos "bir REST API oluştur"
   taaos "create a REST API"
   ```

2. **Doğal dil kullanın**
   ```bash
   taaos "bana bir web scraper lazım"
   taaos "I need a web scraper"
   ```

3. **Spesifik olun**
   ```bash
   # Daha iyi
   taaos "FastAPI ile JWT authentication sistemi yap"
   
   # Daha az spesifik
   taaos "authentication yap"
   ```

4. **Bağlam verin**
   ```bash
   taaos "PostgreSQL veritabanı için bu sorguyu optimize et: SELECT..."
   ```

## Sorun Giderme

### Neural Engine çalışmıyor

```bash
sudo systemctl status taaos-neural-engine
sudo systemctl restart taaos-neural-engine
```

### Ollama modelleri yok

```bash
taaos-ai-models
# Ardından "2" seçerek standard profili yükleyin
```

### Yavaş yanıt

```bash
# Lightweight model kullanın
ollama pull phi3:latest
```

## Daha Fazla Bilgi

- GitHub: https://github.com/tahasezer/taaos
- Dokümantasyon: /usr/share/doc/taaos/
- Örnekler: /usr/share/doc/taaos/ai-examples.md
