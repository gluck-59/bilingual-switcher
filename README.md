# Bilingual Switcher (форк)

Форк проекта [Bilingual Switcher](https://github.com/komandakycto/bilingual-switcher) от автора komandakycto, распространяется по лицензии [MIT](LICENSE).

Приложение для macOS в строке меню: конвертирует выделенный текст между любыми двумя установленными раскладками клавиатуры (например, английская ↔ русская) по глобальной горячей клавише.

## Скачать

Скачайте последний релиз: [BilingualSwitcher.dmg](https://github.com/gluck-59/bilingual-switcher/releases/latest/download/BilingualSwitcher.dmg)

Приложение подписано self-signed (не нотаризовано). При первом запуске macOS может показать предупреждение Gatekeeper — разрешите через «Open Anyway» (Системные настройки → Конфиденциальность и безопасность) или выполните:

```bash
xattr -cr /Applications/BilingualSwitcher.app
```

## Отличия от оригинала

1. **Конвертация последнего слова, если ничего не выделено** — при пустом выделении приложение само выделяет предыдущее слово и конвертирует его.
2. **Локализация интерфейса на русский** — окно настроек, меню и алерты переведены на русский.
3. **Поддержка macOS 12** — минимальная версия снижена с macOS 13 до macOS 12 (Monterey).
4. **Авто-открытие настроек доступности** — при отсутствии разрешения приложение само открывает нужный раздел Системных настроек.
5. **Новые иконки** — иконка приложения и глиф в строке меню.

## Оригинальный проект

- GitHub: https://github.com/komandakycto/bilingual-switcher
- Лицензия: MIT — см. [LICENSE](LICENSE)

## Сборка

Требуется Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/gluck-59/bilingual-switcher.git
cd bilingual-switcher
make setup     # загрузка фреймворка Sparkle
make           # сборка универсального бинарника → build/BilingualSwitcher.app
make install   # копирование в /Applications
```

## Лицензия

[MIT](LICENSE)