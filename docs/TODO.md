# TODO

Список оставшихся задач перед публичным релизом. Заменяет предрелизный аудит (2026-04-14): решённые пункты отмечены ниже для истории.

## Актуальные задачи

1. **Нотаризация** — главный блокер публичного релиза. Сейчас `Makefile:61-65` подписывает ad-hoc (`--sign -`) при отсутствии identity, DMG не нотаризован и не stapled. Нужно: Developer ID + Hardened Runtime, подписать app и DMG, нотаризовать и stapled, проверить артефакт на чистой машине.
2. **Фиксированные фреймы окон** — `PreferencesWindow` и `AboutWindow` построены на ручных `NSRect`. Перевести на Auto Layout (`NSStackView` + constraints), чтобы UI масштабировался под локализацию и крупные шрифты.
3. **Проверка целостности Sparkle** — `Makefile:164` качает `curl -sfL` без проверки SHA-256. Запинить версию и проверять checksum архива.
4. **Обработка `SMAppService.Status.requiresApproval`** — `PreferencesWindow:337-347` учитывает только `.enabled`. При `requiresApproval` объяснять пользователю и открывать System Settings (`SMAppService.openSystemSettingsLoginItems()`).

## Решено (из предрелизного аудита)

- Universal-сборка (arm64 + x86_64 через `lipo`) — не зависит от хоста.
- 123 unit-теста ядра (LayoutConverter, HotkeyManager и др.).
- Переключение на точную раскладку (`TISSelectInputSource(target.source)`), а не по коду языка.
- Фолбэк Accessibility открывает System Settings напрямую, без зависимости от разрешения уведомлений.
- Ошибки регистрации хоткея не молчаливы — общий `registrationFailed` для обоих путей.
- Sparkle-конвейер: `docs/appcast.xml` + release CI (подпись, DMG/ZIP, обновление appcast и cask).
- Accessibility-метаданные статус-айта (`toolTip` + `setAccessibilityLabel`).
- Проверка Accessibility в момент срабатывания хоткея, а не на каждом запуске.
- Убраны «coming soon»-секции и неиспользуемый лендинг `docs/`.
- Кнопка GitHub в окне «О программе» ведёт на форк.