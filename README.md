# Bilingual Switcher (форк)

Форк проекта [Bilingual Switcher](https://github.com/komandakycto/bilingual-switcher) от автора komandakycto, распространяется по лицензии [MIT](LICENSE).

Приложение для macOS в строке меню: конвертирует выделенный текст между любыми двумя установленными раскладками клавиатуры (например, английская ↔ русская) по глобальной горячей клавише.

## Скачать

Скачайте последний релиз: [BilingualSwitcher.dmg](https://github.com/gluck-59/bilingual-switcher/releases/latest/download/BilingualSwitcher.dmg)

Приложение подписано self-signed (не нотаризовано). При первом запуске macOS может показать предупреждение Gatekeeper — разрешите через «Open Anyway» (Системные настройки → Конфиденциальность и безопасность) или выполните:

```bash
xattr -cr /Applications/BilingualSwitcher.app
```

## Внесённые изменения

1. **Повторная конвертация с выбором последнего слова** — если текст не выделен, горячая клавиша теперь выделяет предыдущее слово и конвертирует его, а не просто издаёт звуковой сигнал.
2. **Новая иконка в строке меню** — две буквы «ЯR» с увеличенными глифами.
3. **Стабильная подпись кода** — приложение подписывается самоподписанным сертификатом «BilingualSwitcher Dev», благодаря чему разрешение macOS на доступность (TCC) переживает пересборки (раньше ad-hoc подпись отзывала его при каждой переустановке).
4. **Локализация интерфейса на русский** — окно настроек, меню, алерты и окно «О программе» переведены на русский.
5. **Поддержка macOS 12** — минимальная версия снижена с macOS 13 до macOS 12 (Monterey). Примечание: «Запуск при входе в систему» требует macOS 13+; на macOS 12 приложение добавляется вручную.

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