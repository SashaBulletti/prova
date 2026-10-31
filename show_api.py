#!/usr/bin/env python3
"""Legge openapi.json (gia' salvato dalla sonda) e stampa, per ogni
comando, COSA va messo nella richiesta (i campi del body).

Non serve login ne' internet: legge solo il file locale openapi.json.
Uso: python3 show_api.py
"""

import json
import sys

METHODS = ("get", "post", "put", "patch", "delete")
# Ci interessano i comandi su pannelli, case, mqtt e login.
KEYWORDS = ("panels", "buildings", "mqtt", "login-check")


def resolve(ref: str, spec: dict) -> dict:
    # ref tipo "#/components/schemas/Panel-panel.write"
    node = spec
    for part in ref.lstrip("#/").split("/"):
        node = node.get(part, {})
    return node


def describe_schema(schema: dict, spec: dict, depth: int = 0) -> None:
    if "$ref" in schema:
        schema = resolve(schema["$ref"], spec)
    required = set(schema.get("required", []))
    props = schema.get("properties", {})
    if not props:
        # magari e' un array di qualcosa
        if schema.get("type") == "array" and "items" in schema:
            print("      (lista di:)")
            describe_schema(schema["items"], spec, depth + 1)
        return
    for name, meta in props.items():
        if "$ref" in meta:
            t = meta["$ref"].split("/")[-1]
        else:
            t = meta.get("type", "?")
            if t == "array" and "items" in meta:
                inner = meta["items"].get("type") or \
                        meta["items"].get("$ref", "?").split("/")[-1]
                t = f"array<{inner}>"
        req = " *OBBLIGATORIO*" if name in required else ""
        ex = meta.get("example")
        ex = f"  es: {ex}" if ex is not None else ""
        print(f"      - {name}: {t}{req}{ex}")


def main() -> None:
    try:
        spec = json.load(open("openapi.json"))
    except FileNotFoundError:
        print("Non trovo openapi.json. Lancia prima: python3 probe_api.py")
        sys.exit(1)

    paths = spec.get("paths", {})
    for p in sorted(paths):
        if not any(k in p.lower() for k in KEYWORDS):
            continue
        for method, info in paths[p].items():
            if method.lower() not in METHODS:
                continue
            summary = info.get("summary") or info.get("description") or ""
            print(f"\n{method.upper()} {p}")
            if summary:
                print(f"    {summary[:90]}")
            # Corpo della richiesta.
            rb = info.get("requestBody", {})
            content = rb.get("content", {})
            if content:
                # prende il primo schema disponibile
                for ctype, cval in content.items():
                    sch = cval.get("schema", {})
                    print(f"    BODY ({ctype}):")
                    describe_schema(sch, spec, 0)
                    break
            else:
                print("    BODY: (nessuno)")


if __name__ == "__main__":
    main()
