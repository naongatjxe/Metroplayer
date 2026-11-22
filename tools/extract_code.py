"""Usage: python extract_code.py METROPLAYER_FULL_CODE.md [output_dir]"""
import pathlib
import re
import sys

src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
out = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else ".")
pattern = re.compile(r"^### `([^`]+)`\n\n```[A-Za-z]*\n(.*?)\n```", re.S | re.M)
count = 0
for m in pattern.finditer(src):
    target = out / m.group(1)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(m.group(2) + "\n", encoding="utf-8")
    count += 1
print(count, "files written to", out)
