from pathlib import Path

path = Path("lib/main.dart")
text = path.read_text(encoding="utf-8")

signature = "String? _resolveMenuPhotoUrl("

def find_matching_brace(s, open_pos):
    depth = 0
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    escape = False

    for i in range(open_pos, len(s)):
        ch = s[i]
        nxt = s[i + 1] if i + 1 < len(s) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
            continue

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
            continue

        if in_single:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_single = False
            continue

        if in_double:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_double = False
            continue

        if ch == "/" and nxt == "/":
            in_line_comment = True
            continue

        if ch == "/" and nxt == "*":
            in_block_comment = True
            continue

        if ch == "'":
            in_single = True
            continue

        if ch == '"':
            in_double = True
            continue

        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i

    return -1

positions = []
start = 0
while True:
    pos = text.find(signature, start)
    if pos < 0:
        break
    positions.append(pos)
    start = pos + 1

print("FOUND:", len(positions), "occurrences")

if len(positions) <= 1:
    print("OK: duplicate not found")
else:
    # Оставляем первую функцию, удаляем все следующие дубли.
    for pos in reversed(positions[1:]):
        open_pos = text.find("{", pos)
        if open_pos < 0:
            raise SystemExit("ERROR: opening brace not found")
        end = find_matching_brace(text, open_pos)
        if end < 0:
            raise SystemExit("ERROR: closing brace not found")

        # Захватываем пустые строки после функции
        remove_end = end + 1
        while remove_end < len(text) and text[remove_end] in "\r\n":
            remove_end += 1

        text = text[:pos] + text[remove_end:]
        print("REMOVED duplicate at", pos)

path.write_text(text, encoding="utf-8")
print("OK: duplicate _resolveMenuPhotoUrl removed")
