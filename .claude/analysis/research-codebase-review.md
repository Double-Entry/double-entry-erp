# Анализ `research_codebase.md` и `codebase-researcher.md`

> Разбор недостатков и предложения перед переработкой. Сравнение — с образцовой парой `document-architecture.md` + `architecture-researcher.md`.

## `research_codebase.md` (команда)

### Критические проблемы

1. **Ничего не делегируется агенту.** Вся спека (процесс, критические правила, output-формат, примеры) живёт в команде — прямо противоположно тому, как устроена `document-architecture.md`.
2. **Устаревшие имена инструментов.** `TaskCreate` (такого нет — есть `TodoWrite`); `Task tool` (реальное имя — `Agent` tool).
3. **Примеры на `.dart`** — проект Python/JS (Frappe/ERPNext). Остаток от чужого шаблона.
4. **Нет YAML frontmatter** (`description`, `argument-hint`) — команда не обнаруживается корректно как skill.
5. **Опечатка:** `## Good vs Bad Rebearch`.
6. **Literal `YYYY-MM-DD`** в шаблоне вместо команды `date +%Y-%m-%d`.
7. **Путь вывода `thoughts/research/`** — в проекте каталога `thoughts/` нет, есть `docs/`. Логичнее `docs/research/YYYY-MM-DD-topic.md`.

### Логические и процессные пробелы

8. **«Initial Response» строка** «I'm ready to research...» — лишняя церемония, особенно когда вопрос уже передан через `$ARGUMENTS`.
9. **Нет шага «прочитать CLAUDE.md / hooks.py / modules.txt»** перед декомпозицией — в Frappe это обязательный первый шаг.
10. **Размытая дихотомия `codebase-researcher` vs `Explore`.** Упоминается «Use an Explore subagent», но в самом файле агент проекта — `codebase-researcher`. Непонятно, когда что использовать.
11. **Нет шага согласования плана** с пользователем до spawning (в `document-architecture` это обязательно перед >3 файлов).
12. **Max 4 parallel** заявлено, но нет правила «если вопрос укладывается в один поиск — не плоди subagent’ов».
13. **Нет фиксации языка** отчёта (EN/RU) — для двуязычного проекта это важно.
14. **Нет раздела «что НЕ делать»** — команды в стиле `document-architecture` должны это декларировать.
15. **Форматирование порвано** в секциях 7 и «Good vs Bad» — отсутствуют тире/переносы строк (`references**no vague descriptions`, `COMPLETELY** no limit/offset`).

### Структурные несоответствия с `document-architecture.md`

16. Нет секций `Goal / How to execute / Constraints` — команда должна быть тонкой.
17. Всё, что начинается с «### 2. Decompose», «### 4. Synthesize», «### 7. Critical Rules» и примеров Good/Bad, **должно жить в агенте**, а не в команде.

---

## `codebase-researcher.md` (агент)

### Критические проблемы

1. **Нет YAML frontmatter.** Отсутствуют `name`, `description`, `tools` — агент не обнаруживается системой корректно и не имеет ограничения инструментария.
2. **Не ограничены tools.** Должен быть read-only (`Read, Grep, Glob, Bash`) — сейчас теоретически может писать/редактировать.
3. **Примеры на `.dart`** — тот же артефакт чужого шаблона.
4. **Нет секций ROLE / RULES / FORMAT / EXAMPLES** — противоположность тому, что мы сделали в `architecture-researcher.md`.

### Содержательные пробелы

5. **Нет Frappe/ERPNext-специфики.** Исследователь не знает про:
   - чтение `<doctype>.json` **полностью** (схема = истина для трассировки полей/пермишенов/воркфлоу);
   - цепочку контроллеров (`StatusUpdater → AccountsController → StockController → Selling/Buying`);
   - события `validate → on_submit → on_cancel` как канонический lifecycle;
   - `hooks.py` как карту сквозных механизмов;
   - `regional_overrides` как точку подмены логики.
6. **Нет формата return-to-parent.** Родительская команда должна сливать результаты — агенту нужен стабильный контракт: `Summary / Findings / Code References / Open Questions`.
7. **Нет явного запрета** на модификацию кода и на предложения «как улучшить» (в `architecture-researcher` это явно есть).
8. **Нет правила «читать файлы полностью без limit/offset»** — в команде оно было, но при выносе в агент потерялось.
9. **Нет правила про `path:line` формат** (markdown-ссылка `[name](path:line)`, а не строка).
10. **Нет примеров happy path / clarifying questions / out-of-scope** — агент-специалист без примеров работает хуже.
11. **Нет metadata-блока** (date/commit/branch) — где его собирать, в агенте или в команде, не определено.

### Мелкие

12. В output format упомянуто `path/to/file.dart:42-89` — диапазоны строк полезны, но пример опять дартовый.
13. Нет указания, что **для broad-поиска** агент может сам вызвать `Explore` subagent (если разрешить ему `tools: Agent`).

---

## Концептуальный вопрос

В `document-architecture` агент **пишет файлы** (нужны `Write/Edit`). Для `codebase-researcher` это вопрос дизайна:

- **Вариант A:** агент read-only, только возвращает findings родителю. Команда `research_codebase` сама пишет финальный документ в `docs/research/`.
- **Вариант B:** агент сам пишет документ в `docs/research/` по единому шаблону.

В текущем `research_codebase.md` это смешано: «Output: Always save to thoughts/research/…» — непонятно, кто сохраняет. **Нужно определиться до правок.**

---

## Предложение по дальнейшим шагам

После выбора пунктов сделать:

1. Новую тонкую команду `.claude/commands/research-codebase.md` (в стиле `document-architecture.md`).
2. Новый агент `.claude/agents/codebase-researcher.md` с полными секциями ROLE / RULES / FORMAT / EXAMPLES, ERPNext-спецификой, контрактом return-to-parent.
3. RU-копии: `.claude/commands/ru/research-codebase.md`, `.claude/agents/ru/codebase-researcher.md`.
4. Удалить старый `research_codebase.md` (нижнее подчёркивание → дефис для единообразия с `document-architecture`).

## Вопросы для согласования

- Какие пункты из списков оставить, какие выкинуть?
- Кто пишет финальный `.md` — агент или команда (вариант A или B)?
- Переименование `research_codebase` → `research-codebase` — ок?
