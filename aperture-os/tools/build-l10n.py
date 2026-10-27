#!/usr/bin/env python3
"""Compile the plasmoid translations into their packages.

  <component>/po/<lang>/plasma_applet_<id>.po
    -> <component>/<id>/contents/locale/<lang>/LC_MESSAGES/plasma_applet_<id>.mo

Plasma loads catalogs from the package's contents/locale, so kpackagetool6
installs them with the plasmoid. Source strings are English; German is a
translation (KDE's i18n treats en_US as the source language and never loads
an English catalog). Only the Python standard library is used.
"""
import ast
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def parse_po(path):
    """Minimal PO parser: msgctxt/msgid/msgstr, no plurals."""
    entries, cur, key = {}, {}, None

    def flush():
        if "msgid" in cur and cur.get("msgstr"):
            mid = cur["msgid"]
            if "msgctxt" in cur:
                mid = cur["msgctxt"] + "\x04" + mid
            entries[mid] = cur["msgstr"]

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith('"'):
            cur[key] += ast.literal_eval(line)
            continue
        word, _, rest = line.partition(" ")
        if word in ("msgctxt", "msgid") and ("msgstr" in cur):
            flush()
            cur = {}
        key = word
        cur[key] = ast.literal_eval(rest)
    flush()
    return entries


def write_mo(entries, path):
    keys = sorted(entries)
    ids = b"".join(k.encode() + b"\0" for k in keys)
    strs = b"".join(entries[k].encode() + b"\0" for k in keys)
    n = len(keys)
    o_ids, o_strs = 28, 28 + n * 8
    data_start = 28 + n * 16
    id_tab, str_tab, off = [], [], data_start
    for k in keys:
        b = k.encode()
        id_tab.append((len(b), off))
        off += len(b) + 1
    for k in keys:
        b = entries[k].encode()
        str_tab.append((len(b), off))
        off += len(b) + 1
    out = struct.pack("<7I", 0x950412DE, 0, n, o_ids, o_strs, 0, 0)
    out += b"".join(struct.pack("<2I", *t) for t in id_tab)
    out += b"".join(struct.pack("<2I", *t) for t in str_tab)
    out += ids + strs
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_bytes() != out:
        path.write_bytes(out)
        return True
    return False


def main():
    count = 0
    for po in sorted(ROOT.glob("*/po/*/plasma_applet_*.po")):
        component, lang = po.parents[2], po.parent.name
        pid = po.stem[len("plasma_applet_"):]
        package = component / pid
        if not (package / "metadata.json").exists():
            print(f"skipping {po.relative_to(ROOT)} (no package {pid})", file=sys.stderr)
            continue
        mo = package / "contents" / "locale" / lang / "LC_MESSAGES" / (po.stem + ".mo")
        changed = write_mo(parse_po(po), mo)
        count += 1
        if changed:
            print(f"  {mo.relative_to(ROOT)}")
    print(f"l10n: {count} Kataloge")


if __name__ == "__main__":
    main()
