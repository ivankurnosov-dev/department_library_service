import subprocess
import re
import os
import sys

# --- НАСТРОЙКИ ---
BACKLOG_FILE = "docs/01-planning/backlog.md"
REPO = "ivankurnosov-dev/department_library_service"
PROJECT_NAME = "department_library_service board"  # Убедись, что название ТОЧНО совпадает с названием доски на GitHub

def parse_backlog(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Ищем блоки, начинающиеся с "## US-"
    pattern = r"## (US-\d+:.*?)(?=\n## |\Z)"
    blocks = re.findall(pattern, content, re.DOTALL)
    
    issues = []
    for block in blocks:
        lines = block.strip().split("\n")
        title_line = lines[0].strip()
        
        # Извлекаем ID и заголовок
        match = re.match(r"(US-\d+):?\s*(.*)", title_line)
        if not match:
            continue
        us_id, title = match.groups()
        full_title = f"{us_id}: {title.strip()}"
        
        # Тело задачи
        body = block.strip()
        
        # Ищем метку (mvp или after-mvp)
        label_match = re.search(r"\*\*Label:\*\*\s*(mvp|after-mvp)", block, re.IGNORECASE)
        label_type = label_match.group(1).lower() if label_match else "after-mvp"
        
        labels = f"story,{label_type}"
        
        issues.append({
            "title": full_title,
            "body": body,
            "labels": labels
        })
    return issues

def create_issue(issue, dry_run=False):
    cmd = [
        "gh", "issue", "create",
        "--repo", REPO,
        "--title", issue["title"],
        "--body", issue["body"],
        "--label", issue["labels"],
        "--assignee", "@me",                # Назначает задачу на тебя
        "--project", PROJECT_NAME           # Добавляет на доску
    ]

    if dry_run:
        print(f" [DRY-RUN] {issue['title']} | Метки: {issue['labels']} | Assignee: @me | Project: {PROJECT_NAME}")
        return

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True, encoding="utf-8")
        print(f" Создано: {issue['title']}")
    except subprocess.CalledProcessError as e:
        print(f" Ошибка при создании {issue['title']}:")
        print(e.stderr)

if __name__ == "__main__":
    dry_run = "--dry-run" in sys.argv
    
    if not os.path.exists(BACKLOG_FILE):
        print(f" Файл {BACKLOG_FILE} не найден! Убедись, что ты в корне проекта.")
        sys.exit(1)
        
    issues = parse_backlog(BACKLOG_FILE)
    print(f"Найдено историй: {len(issues)}\n")
    
    for issue in issues:
        create_issue(issue, dry_run)
        
    if not dry_run:
        print("\n Все задачи успешно созданы, назначены на тебя и добавлены на доску!")