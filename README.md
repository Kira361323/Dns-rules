# Dns-rules

Готовые правила и конфигурации для **sing-box**, позволяющие направлять DNS-запросы отдельных приложений или доменов через GeoHide (DNS-сервер для обхода геоблокировок). Весь остальной трафик системы использует стандартный зашифрованный DNS (например, `dns.google`).

Репозиторий решает задачу точечной подмены DNS без необходимости проксировать или туннелировать весь трафик устройства.

## 📁 Структура репозитория

### `geohide.srs`
Скомпилированный бинарный rule-set (формат sing-box `.srs`) со списком доменов. Собирается автоматически через GitHub Actions на основе агрегации списков из двух источников:
- [Internet-Helper/GeoHideDNS](https://github.com/Internet-Helper/GeoHideDNS) — обход геоблокировок.
- [ImMALWARE/dns.malw.link](https://github.com/ImMALWARE/dns.malw.link) — блокировка рекламы и вредоносных доменов.

Подключается в конфиге sing-box как remote rule-set:
```json
{
  "type": "remote",
  "tag": "geohide-domains",
  "format": "binary",
  "url": "https://github.com/Kira361323/Dns-rules/releases/latest/download/geohide.srs",
  "update_interval": "24h"
}
```

### 📂 `sing-box-profile/`
Готовые конфигурационные файлы `.json`. Все используют базовую схему: `dns.google` (DoT) как сервер по умолчанию, `dns.geohide.ru` (DoH) для выбранных целей.

| Файл | Что направляется на GeoHide | Механизм |
|---|---|---|
| [`1-only-apps.json`](sing-box-profile/1-only-apps.json) | Только приложения из списка (по `package_name`) | Одно DNS-правило с массивом пакетов Android-приложений |
| [`2-only-domains.json`](sing-box-profile/2-only-domains.json) | Только домены из списка | DNS-правило, ссылающееся на `geohide.srs` как remote rule-set |
| [`3-combined-logical.json`](sing-box-profile/3-combined-logical.json) | Приложения **и** домены из списка | Одно DNS-правило типа `logical` с режимом `or` |
| [`4-combined-separate-rules.json`](sing-box-profile/4-combined-separate-rules.json) | Приложения **и** домены из списка | Два отдельных DNS-правила подряд (функционально аналогично варианту 3, но проще для чтения) |
| [`singbox-dns-only.json`](sing-box-profile/singbox-dns-only.json) | Только приложения из списка (базовый) | Исходный минимальный конфиг без remote rule-set, список пакетов задан вручную |

> **Список приложений в правилах**: ChatGPT, Claude, Copilot, DeepL, DeepSeek, DuckDuckGo, Firefox, Gemini, Google App, Grok, Leonardo.Ai, Mistral, Google Tailwind, Qwen, Suno, Telegram Beta.

## 🚀 Как использовать

1. Перейди в папку [`sing-box-profile/`](sing-box-profile/) и выбери подходящий `.json` файл.
2. Используй его как основной конфиг в sing-box или скопируй из него блоки `dns` и `route` в свой существующий конфиг.
3. При необходимости отредактируй массив `package_name` под свои приложения. Актуальные имена пакетов можно найти в URL страницы приложения в Google Play (параметр `id=`).
4. Файл `geohide.srs` подтягивается автоматически по ссылке из релиза. Ручное обновление не требуется, но при желании можно изменить параметр `update_interval`.

## ⚠️ Дисклеймер

Конфигурации подменяют **только DNS-резолвинг** для указанных доменов или приложений. Это не туннелирование и не проксирование трафика. Если сервис блокируется по IP или SNI, данные конфиги не решат проблему.

## 🙏 Благодарности

Списки доменов агрегируются из нескольких открытых источников. Спасибо авторам за поддержку их в актуальном состоянии:
- [Internet-Helper/GeoHideDNS](https://github.com/Internet-Helper/GeoHideDNS)
- [ImMALWARE/dns.malw.link](https://github.com/ImMALWARE/dns.malw.link)