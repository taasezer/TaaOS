# TaaOS AI - Örnek Kullanımlar

## Hızlı Başlangıç

### Basit Örnekler

```bash
# Yardım al
taaos -h
taaos --help

# Doğal dil ile komut
taaos "merhaba dünya programı yaz"
taaos "hello world program oluştur"
```

## Kod Oluşturma Örnekleri

### Python

```bash
# Web scraper
taaos "BeautifulSoup ile web scraper yap"

# REST API
taaos "FastAPI ile CRUD API oluştur"

# Data processing
taaos "pandas ile CSV dosyası oku ve analiz et"

# Machine Learning
taaos "scikit-learn ile linear regression modeli yap"
```

### JavaScript/TypeScript

```bash
# React component
taaos "React ile todo list component yap"

# Express API
taaos "Express.js ile authentication API oluştur"

# TypeScript interface
taaos "User için TypeScript interface tanımla"
```

### Rust

```bash
# CLI tool
taaos "Rust ile command line tool yap"

# Web server
taaos "Actix-web ile REST API oluştur"

# Async code
taaos "Tokio ile async file reader yaz"
```

## Kod İnceleme Örnekleri

```bash
# Python kodu incele
taaos review app.py

# Security check
taaos "bu kodun güvenlik açıklarını bul: auth.py"

# Performance analysis
taaos "bu kodun performansını analiz et: database.py"

# Best practices
taaos "bu kod best practice'lere uyuyor mu: utils.py"
```

## Test Oluşturma Örnekleri

```bash
# Unit tests
taaos test calculator.py

# Integration tests
taaos "api.py için integration test yaz"

# Mock kullanımı
taaos "database bağlantısını mock'layarak test yaz"
```

## Hata Çözme Örnekleri

```bash
# Python hatası
taaos explain "NameError: name 'x' is not defined"

# JavaScript hatası
taaos "bu ne demek: TypeError: Cannot read property of undefined"

# Rust hatası
taaos explain "error[E0382]: borrow of moved value"

# SQL hatası
taaos "bu SQL hatasını açıkla: syntax error near FROM"
```

## Optimizasyon Örnekleri

```bash
# SQL optimization
taaos optimize-query "SELECT * FROM users WHERE age > 18" postgresql

# Code optimization
taaos "bu kodu optimize et: slow_function.py"

# Algorithm improvement
taaos "bu algoritmanın time complexity'sini düşür"
```

## Dokümantasyon Örnekleri

```bash
# Function documentation
taaos document utils.py

# Class documentation
taaos "User class için docstring yaz"

# API documentation
taaos "bu API endpoint'i için OpenAPI spec oluştur"
```

## Kod Çevirisi Örnekleri

```bash
# Python to JavaScript
taaos translate script.py python javascript

# JavaScript to TypeScript
taaos "bu JS kodunu TypeScript'e çevir: app.js"

# Python to Rust
taaos translate algorithm.py python rust
```

## Log Analizi Örnekleri

```bash
# System logs
taaos analyze-logs /var/log/syslog

# Application logs
taaos "nginx error loglarını analiz et"

# Custom logs
taaos analyze-logs /var/log/myapp/error.log
```

## Mimari Önerileri

```bash
# E-commerce
taaos architecture "e-commerce platform with 1M users"

# Social media
taaos "Instagram benzeri uygulama için tech stack öner"

# Blog platform
taaos "blog sitesi için mimari öner"

# Microservices
taaos "microservices mimarisi için öneri"
```

## Gerçek Dünya Senaryoları

### Senaryo 1: Web Uygulaması Geliştirme

```bash
# 1. Proje başlat
taaos "Next.js projesi için klasör yapısı oluştur"

# 2. API oluştur
taaos "FastAPI ile user authentication API yap"

# 3. Database model
taaos "SQLAlchemy ile User ve Post modelleri oluştur"

# 4. Test yaz
taaos test api/routes.py

# 5. Dokümante et
taaos document api/routes.py
```

### Senaryo 2: Hata Ayıklama

```bash
# 1. Hatayı analiz et
taaos explain "AttributeError: 'NoneType' object has no attribute 'id'"

# 2. Kodu incele
taaos review buggy_code.py

# 3. Fix önerisi al
taaos "bu hatayı nasıl düzeltebilirim: buggy_code.py"

# 4. Test yaz
taaos "bu bug için regression test yaz"
```

### Senaryo 3: Performans İyileştirme

```bash
# 1. Slow query bul
taaos analyze-logs /var/log/postgresql/slow-queries.log

# 2. Optimize et
taaos optimize-query "SELECT * FROM orders JOIN users ON..."

# 3. Kodu optimize et
taaos "bu fonksiyonu optimize et: slow_function.py"

# 4. Benchmark
taaos "bu kod için benchmark test yaz"
```

### Senaryo 4: Yeni Teknoloji Öğrenme

```bash
# 1. Örnek kod iste
taaos "Rust ile basit web server örneği"

# 2. Açıklama al
taaos "Rust ownership nedir açıkla"

# 3. Kod çevir
taaos translate my_python_code.py python rust

# 4. Best practices öğren
taaos "Rust best practices nelerdir"
```

## Komut Kombinasyonları

```bash
# Kod oluştur ve test yaz
taaos "calculator.py oluştur" && taaos test calculator.py

# İncele ve optimize et
taaos review slow.py && taaos "slow.py'yi optimize et"

# Oluştur ve dokümante et
taaos "API endpoint yaz" && taaos document api.py
```

## Pro İpuçları

### 1. Spesifik Ol

```bash
# ❌ Kötü
taaos "kod yaz"

# ✅ İyi
taaos "FastAPI ile JWT authentication endpoint'i yaz"
```

### 2. Bağlam Ver

```bash
# ❌ Kötü
taaos "optimize et"

# ✅ İyi
taaos "PostgreSQL için bu sorguyu optimize et: SELECT..."
```

### 3. Dil Belirt

```bash
# ❌ Belirsiz
taaos review mycode

# ✅ Net
taaos review mycode.py python
```

### 4. Örneklerle Açıkla

```bash
# ✅ Çok iyi
taaos "kullanıcı login sistemi yap, email ve password ile, JWT token dönsün"
```

## Klavye Kısayolları

Bash alias'ları ekleyerek daha hızlı kullanın:

```bash
# ~/.bashrc veya ~/.zshrc
alias ai='taaos'
alias code-gen='taaos generate'
alias code-review='taaos review'
alias code-test='taaos test'
alias explain='taaos explain'

# Kullanım
ai "web scraper yap"
code-gen "REST API" python
code-review app.py
```

## Daha Fazla Örnek

Daha fazla örnek için:
- `/usr/share/doc/taaos/examples/` klasörüne bakın
- `taaos -h` ile yardım menüsünü görün
- TaaOS AI GUI'yi açın: `taaos-ai-gui`
