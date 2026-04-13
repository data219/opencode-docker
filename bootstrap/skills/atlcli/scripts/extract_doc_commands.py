#!/usr/bin/env python3
"""Extract atlcli command lines from atlcli.sh docs sitemap.

Usage:
  extract_doc_commands.py <output-dir> [--tag YYYY-MM-DD]
"""

from __future__ import annotations

import argparse
import hashlib
import html
import platform
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import urlopen

NS = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8", "ignore")).hexdigest()


def fetch_text(url: str) -> str:
    with urlopen(url, timeout=20) as resp:
        return resp.read().decode("utf-8", "ignore")


def extract_urls_from_sitemap(xml_text: str) -> list[str]:
    root = ET.fromstring(xml_text)
    return [loc.text for loc in root.findall('.//sm:loc', NS) if loc.text]


def extract_commands(page_html: str) -> set[str]:
    commands: set[str] = set()
    for m in re.finditer(r'data-code="(.*?)"', page_html, flags=re.S):
        block = html.unescape(m.group(1)).replace("\x7f", "\n")
        for line in block.splitlines():
            line = re.sub(r"\s+#.*$", "", line.strip())
            line = re.sub(r"\s+", " ", line)
            if line.startswith("atlcli "):
                commands.add(line)
    for m in re.finditer(r'<(?:pre|code)[^>]*>(.*?)</(?:pre|code)>', page_html, flags=re.S | re.I):
        block = html.unescape(re.sub(r"<[^>]+>", "\n", m.group(1))).replace("\x7f", "\n")
        for line in block.splitlines():
            line = re.sub(r"\s+#.*$", "", line.strip())
            line = re.sub(r"\s+", " ", line)
            if line.startswith("atlcli "):
                commands.add(line)
    return commands


def is_valid_command_line(line: str) -> bool:
    if not line.startswith("atlcli "):
        return False
    lowered = line.lower()
    noise_fragments = [
        " is up to date",
        " has issues",
        " is healthy",
        "<tab>",
        "git:commit",
        "documentation\"/>",
        "not affiliated",
        "trademarks of atlassian",
    ]
    if any(frag in lowered for frag in noise_fragments):
        return False
    if line.endswith("\\"):
        return False
    tokens = line.split()
    if len(tokens) < 2:
        return False
    if not tokens[1].startswith("-") and not re.match(r"^[a-z][a-z0-9-]*$", tokens[1]):
        return False
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("output_dir")
    parser.add_argument("--tag", default=datetime.now(timezone.utc).strftime("%Y-%m-%d"))
    parser.add_argument("--allow-partial", action="store_true", help="Exit 0 even when some URLs fail to crawl")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    tag = args.tag
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    started_at = datetime.now(timezone.utc).isoformat()

    idx = fetch_text("https://atlcli.sh/sitemap-index.xml")
    idx_hash = sha256_text(idx)
    sitemap_urls = extract_urls_from_sitemap(idx)

    doc_urls: list[str] = []
    crawl_manifest: list[tuple[str, str, int, str]] = []
    sitemap_hashes: list[tuple[str, str, str]] = []
    all_cmds: set[str] = set()
    error_count = 0

    for sitemap_url in sitemap_urls:
        try:
            sm_xml = fetch_text(sitemap_url)
            sm_hash = sha256_text(sm_xml)
            sitemap_hashes.append((sitemap_url, "ok", sm_hash))
        except Exception:
            error_count += 1
            sitemap_hashes.append((sitemap_url, "error", ""))
            continue
        for url in extract_urls_from_sitemap(sm_xml):
            if not url.startswith("https://atlcli.sh/"):
                continue
            doc_urls.append(url)
            try:
                html_text = fetch_text(url)
                extracted = extract_commands(html_text)
                all_cmds.update(extracted)
                crawl_manifest.append((url, "ok", len(extracted), sha256_text(html_text)))
            except Exception:
                error_count += 1
                crawl_manifest.append((url, "error", 0, ""))

    doc_urls = sorted(set(doc_urls))
    filtered_cmds = sorted(c for c in all_cmds if is_valid_command_line(c))

    doc_urls_file = out_dir / f"doc-urls-{tag}.txt"
    commands_file = out_dir / f"extracted-commands-{tag}.txt"
    manifest_file = out_dir / f"crawl-manifest-{tag}.tsv"
    sitemap_hashes_file = out_dir / f"sitemap-hashes-{tag}.tsv"
    meta_file = out_dir / f"extract-meta-{tag}.txt"

    doc_urls_file.write_text("\n".join(doc_urls) + "\n", encoding="utf-8")
    commands_file.write_text("\n".join(filtered_cmds) + "\n", encoding="utf-8")

    with manifest_file.open("w", encoding="utf-8") as f:
        f.write("url\tstatus\tcommand_count\thtml_sha256\n")
        for url, status, count, html_hash in crawl_manifest:
            f.write(f"{url}\t{status}\t{count}\t{html_hash}\n")

    with sitemap_hashes_file.open("w", encoding="utf-8") as f:
        f.write("sitemap_url\tstatus\tsha256\n")
        for sitemap_url, status, sha in sitemap_hashes:
            f.write(f"{sitemap_url}\t{status}\t{sha}\n")

    script_hash = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    with meta_file.open("w", encoding="utf-8") as f:
        f.write(f"started_at_utc={started_at}\n")
        f.write(f"finished_at_utc={datetime.now(timezone.utc).isoformat()}\n")
        f.write(f"tag={tag}\n")
        f.write(f"python={sys.version.split()[0]}\n")
        f.write(f"platform={platform.platform()}\n")
        f.write(f"allow_partial={str(args.allow_partial).lower()}\n")
        f.write(f"script_sha256={script_hash}\n")
        f.write(f"sitemap_index_sha256={idx_hash}\n")
        f.write(f"sitemap_sources={len(sitemap_urls)}\n")
        f.write(f"error_count={error_count}\n")
        f.write(f"doc_urls={len(doc_urls)}\n")
        f.write(f"commands={len(filtered_cmds)}\n")
        f.write(f"doc_urls_file={doc_urls_file.name}\n")
        f.write(f"commands_file={commands_file.name}\n")
        f.write(f"manifest_file={manifest_file.name}\n")
        f.write(f"sitemap_hashes_file={sitemap_hashes_file.name}\n")

    print(f"doc_urls={len(doc_urls)}")
    print(f"commands={len(filtered_cmds)}")
    print(f"meta_file={meta_file.name}")
    print(f"error_count={error_count}")
    if error_count > 0 and not args.allow_partial:
        print("crawl_status=failed (partial errors detected)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
