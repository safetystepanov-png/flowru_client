from pathlib import Path

path = Path("patch_client.py")
text = path.read_text(encoding="utf-8")

old = "text, count = controllers_re.subn(controllers_new, text, count=1)"
new = "text, count = controllers_re.subn(lambda m: controllers_new, text, count=1)"

if old not in text:
    print("WARN: строка для замены не найдена")
    print("Похожие строки:")
    for line in text.splitlines():
        if "controllers_re.subn" in line:
            print(line)
else:
    text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")
    print("OK: patch_client.py fixed")
