# Universal Search

Universal Search — термінальний пошук із кольоровим інтерфейсом та CLI-режимом.

## Можливості

- Інтерактивне меню.
- CLI-запуск.
- Команди з великими й малими літерами.
- Установлення в `/usr/local`.
- Деінсталяція без видалення файлів проєкту.

## Встановлення

Потрібні Bash та `curl` або `wget`. Для системного встановлення потрібен
`sudo` або root-доступ.

```bash
curl -fsSL https://raw.githubusercontent.com/fokompo/universal-search/main/install.sh -o install.sh
bash install.sh
```

Або після клонування репозиторію:

```bash
git clone https://github.com/fokompo/universal-search.git
cd universal-search
bash install.sh
```

Інсталятор використовує локальний файл `search`, якщо він є поруч.
Інакше завантажує його з гілки `main`.

## Команди

| Команда | Призначення |
|---|---|
| `S` | Інтерактивне меню |
| `Search` | Інтерактивне меню |
| `s` | CLI-режим |
| `search` | CLI-режим |

У CLI-режимі доступні аргументи, які підтримує сама програма. Щоб побачити
довідку, запусти `search --help`, якщо ця опція підтримується поточною версією.

## Видалення

У клонованому репозиторії:

```bash
bash uninstall.sh
```

Також можна завантажити деінсталятор і запустити його:

```bash
curl -fsSL https://raw.githubusercontent.com/fokompo/universal-search/main/uninstall.sh -o uninstall.sh
bash uninstall.sh
```

## Підтримка Linux

Інсталятор не використовує `pacman`, `apt` чи `dnf`: він встановлює програму
у стандартні каталоги `/usr/local/lib` і `/usr/local/bin`. Це підходить для
більшості дистрибутивів Linux, де доступні Bash та стандартні Unix-команди.

Зовнішні інструменти, потрібні для окремих функцій самої програми, можуть
встановлюватися через пакетний менеджер конкретного дистрибутива.

## Ліцензія

MIT. Див. файл [LICENSE](LICENSE).
