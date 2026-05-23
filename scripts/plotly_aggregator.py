#!/usr/bin/env python3
"""
Plotly HTML Aggregator

複数の Plotly figure を 1 つの HTML にタブ表示で集約する CLI。

想定入力:
- 個別の Plotly HTML ファイル
  - plotly.io.write_html(...)
  - fig.write_html(...)
- full_html=True / False のどちらでも一応扱えるようにしているが、
  基本的には「各ファイルに Plotly のグラフが 1 つ入っている」前提。

使い方:
    python plotly_tabbed_aggregator.py \
        --output merged.html \
        chart1.html chart2.html chart3.html

ディレクトリをまとめて指定することも可能:
    python plotly_tabbed_aggregator.py \
        --output merged.html \
        --glob "charts/*.html"

両方併用も可能:
    python plotly_tabbed_aggregator.py \
        --output merged.html \
        chart1.html \
        --glob "charts/*.html"
"""

from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path
from typing import Iterable, List, Sequence


SCRIPT_BLOCK_RE = re.compile(r"<script\b[^>]*>.*?</script>", re.IGNORECASE | re.DOTALL)
BODY_RE = re.compile(r"<body\b[^>]*>(.*?)</body>", re.IGNORECASE | re.DOTALL)
TITLE_RE = re.compile(r"<title\b[^>]*>(.*?)</title>", re.IGNORECASE | re.DOTALL)


class AggregationError(Exception):
    """集約処理に関するエラー。"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="複数の Plotly HTML を 1 つのタブ付き HTML に集約する"
    )
    parser.add_argument(
        "inputs",
        nargs="*",
        help="入力 HTML ファイル",
    )
    parser.add_argument(
        "--glob",
        action="append",
        default=[],
        dest="glob_patterns",
        help="追加で取り込む glob パターン。複数回指定可。例: --glob 'charts/*.html'",
    )
    parser.add_argument(
        "-o",
        "--output",
        required=True,
        help="出力先 HTML ファイル",
    )
    parser.add_argument(
        "--title",
        default="Plotly Charts",
        help="出力 HTML の title",
    )
    parser.add_argument(
        "--sort",
        choices=["name", "input-order"],
        default="input-order",
        help="タブ順。デフォルトは入力順",
    )
    return parser.parse_args()


def resolve_input_files(inputs: Sequence[str], glob_patterns: Sequence[str], sort_mode: str) -> List[Path]:
    files: List[Path] = []
    seen: set[Path] = set()

    def add_file(path: Path) -> None:
        resolved = path.expanduser().resolve()
        if resolved in seen:
            return
        if not resolved.exists():
            raise AggregationError(f"入力ファイルが存在しません: {path}")
        if not resolved.is_file():
            raise AggregationError(f"入力パスがファイルではありません: {path}")
        if resolved.suffix.lower() not in {'.html', '.htm'}:
            raise AggregationError(f"HTML ファイルではありません: {path}")
        seen.add(resolved)
        files.append(resolved)

    for input_path in inputs:
        add_file(Path(input_path))

    for pattern in glob_patterns:
        matches = sorted(Path().glob(pattern))
        if not matches:
            raise AggregationError(f"glob に一致するファイルがありません: {pattern}")
        for match in matches:
            add_file(match)

    if not files:
        raise AggregationError("入力ファイルがありません。ファイルパスまたは --glob を指定してください。")

    if sort_mode == "name":
        files.sort(key=lambda p: p.name.lower())

    return files


def extract_body_content(raw_html: str) -> str:
    """
    HTML 全体から body 部分を抽出する。
    body がなければ元文字列を返す。
    """
    match = BODY_RE.search(raw_html)
    if match:
        return match.group(1).strip()
    return raw_html.strip()


def extract_scripts(raw_html: str) -> List[str]:
    return SCRIPT_BLOCK_RE.findall(raw_html)


def strip_scripts(raw_html: str) -> str:
    return SCRIPT_BLOCK_RE.sub("", raw_html)


def pick_title(raw_html: str, fallback: str) -> str:
    match = TITLE_RE.search(raw_html)
    if match:
        title = re.sub(r"\s+", " ", match.group(1)).strip()
        if title:
            return title
    return fallback


def dedupe_scripts(script_blocks: Iterable[str]) -> List[str]:
    unique: List[str] = []
    seen: set[str] = set()
    for script in script_blocks:
        normalized = script.strip()
        if normalized in seen:
            continue
        seen.add(normalized)
        unique.append(normalized)
    return unique


def sanitize_dom_id(text: str, index: int) -> str:
    base = re.sub(r"[^a-zA-Z0-9_-]+", "-", text).strip("-")
    if not base:
        base = f"tab-{index}"
    return f"tab-{index}-{base}"


class ChartDocument:
    def __init__(self, path: Path, tab_name: str, content_html: str, scripts: List[str]) -> None:
        self.path = path
        self.tab_name = tab_name
        self.content_html = content_html
        self.scripts = scripts
        self.dom_id = ""


def load_chart_document(path: Path) -> ChartDocument:
    raw_html = path.read_text(encoding="utf-8")

    body_content = extract_body_content(raw_html)
    scripts = extract_scripts(body_content)
    body_without_scripts = strip_scripts(body_content).strip()

    # Plotly の場合、div 本体と script が必要。script を後段でタブごとに戻す。
    if not body_without_scripts and not scripts:
        raise AggregationError(f"有効な HTML コンテンツを抽出できませんでした: {path}")

    tab_name = path.name
    _ = pick_title(raw_html, tab_name)  # 将来拡張用。現状タブ名は仕様どおりファイル名固定。

    return ChartDocument(
        path=path,
        tab_name=tab_name,
        content_html=body_without_scripts,
        scripts=scripts,
    )


def render_output_html(documents: Sequence[ChartDocument], page_title: str) -> str:
    all_scripts = dedupe_scripts(
        script
        for doc in documents
        for script in doc.scripts
        if "window.PlotlyConfig" in script or "plotly-" in script.lower() or "cdn.plot.ly" in script.lower()
    )

    tab_buttons: List[str] = []
    tab_panels: List[str] = []
    panel_script_blocks: List[str] = []

    for index, doc in enumerate(documents):
        doc.dom_id = sanitize_dom_id(doc.path.stem, index)
        active_class = " active" if index == 0 else ""
        active_attr = "true" if index == 0 else "false"
        hidden_attr = "" if index == 0 else " hidden"

        escaped_tab_name = html.escape(doc.tab_name)

        tab_buttons.append(
            f'''<button class="tab-button{active_class}" type="button" role="tab" '''
            f'''aria-selected="{active_attr}" aria-controls="{doc.dom_id}" '''
            f'''id="btn-{doc.dom_id}" data-target="{doc.dom_id}" title="{escaped_tab_name}">'''
            f'''{escaped_tab_name}</button>'''
        )

        tab_panels.append(
            f'''<section class="tab-panel{active_class}" id="{doc.dom_id}" role="tabpanel" '''
            f'''aria-labelledby="btn-{doc.dom_id}"{hidden_attr}>\n{doc.content_html}\n</section>'''
        )

        non_bootstrap_scripts = [
            s for s in doc.scripts
            if s.strip() not in all_scripts
        ]
        if non_bootstrap_scripts:
            panel_script_blocks.append("\n".join(non_bootstrap_scripts))

    bootstrap_scripts_html = "\n".join(all_scripts)
    panel_scripts_html = "\n".join(panel_script_blocks)

    return f'''<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(page_title)}</title>
  <style>
    :root {{
      --border: #d0d7de;
      --bg-soft: #f6f8fa;
      --bg-active: #ffffff;
      --text: #24292f;
      --accent: #0969da;
    }}

    * {{ box-sizing: border-box; }}

    body {{
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      color: var(--text);
      background: #fff;
    }}

    .page {{
      max-width: 1600px;
      margin: 0 auto;
      padding: 16px;
    }}

    h1 {{
      font-size: 20px;
      margin: 0 0 12px;
    }}

    .tabs {{
      display: flex;
      gap: 4px;
      flex-wrap: wrap;
      border-bottom: 1px solid var(--border);
      margin-bottom: 16px;
      position: sticky;
      top: 0;
      background: rgba(255,255,255,0.95);
      backdrop-filter: blur(6px);
      padding-top: 8px;
      z-index: 10;
    }}

    .tab-button {{
      border: 1px solid var(--border);
      border-bottom: none;
      background: var(--bg-soft);
      color: var(--text);
      padding: 10px 14px;
      border-top-left-radius: 8px;
      border-top-right-radius: 8px;
      cursor: pointer;
      font-size: 14px;
      max-width: 360px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }}

    .tab-button.active {{
      background: var(--bg-active);
      color: var(--accent);
      font-weight: 600;
      position: relative;
      top: 1px;
    }}

    .tab-button:hover {{
      background: #eef4fb;
    }}

    .tab-panel {{
      display: none;
      width: 100%;
    }}

    .tab-panel.active {{
      display: block;
    }}

    .tab-panel[hidden] {{
      display: none !important;
    }}

    .tab-panel > div {{
      width: 100%;
    }}
  </style>
  {bootstrap_scripts_html}
</head>
<body>
  <div class="page">
    <h1>{html.escape(page_title)}</h1>
    <div class="tabs" role="tablist" aria-label="Plotly charts tabs">
      {'\n      '.join(tab_buttons)}
    </div>
    <div class="tab-panels">
      {'\n      '.join(tab_panels)}
    </div>
  </div>

  {panel_scripts_html}

  <script>
    (function () {{
      const buttons = Array.from(document.querySelectorAll('.tab-button'));
      const panels = Array.from(document.querySelectorAll('.tab-panel'));

      function activate(targetId) {{
        buttons.forEach((button) => {{
          const isActive = button.dataset.target === targetId;
          button.classList.toggle('active', isActive);
          button.setAttribute('aria-selected', isActive ? 'true' : 'false');
        }});

        panels.forEach((panel) => {{
          const isActive = panel.id === targetId;
          panel.classList.toggle('active', isActive);
          if (isActive) {{
            panel.removeAttribute('hidden');
          }} else {{
            panel.setAttribute('hidden', 'hidden');
          }}
        }});

        if (window.Plotly) {{
          const activePanel = document.getElementById(targetId);
          if (activePanel) {{
            const plotlyRoots = activePanel.querySelectorAll('.plotly-graph-div');
            plotlyRoots.forEach((el) => {{
              try {{
                window.Plotly.Plots.resize(el);
              }} catch (e) {{
                console.warn('Plotly resize failed:', e);
              }}
            }});
          }}
        }}
      }}

      buttons.forEach((button) => {{
        button.addEventListener('click', () => activate(button.dataset.target));
      }});

      if (buttons.length > 0) {{
        activate(buttons[0].dataset.target);
      }}
    }})();
  </script>
</body>
</html>
'''


def main() -> int:
    args = parse_args()

    try:
        input_files = resolve_input_files(args.inputs, args.glob_patterns, args.sort)
        documents = [load_chart_document(path) for path in input_files]
        output_html = render_output_html(documents, args.title)

        output_path = Path(args.output).expanduser().resolve()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output_html, encoding="utf-8")

        print(f"出力しました: {output_path}")
        print("対象ファイル:")
        for doc in documents:
            print(f"- {doc.path.name}")
        return 0

    except AggregationError as e:
        print(f"エラー: {e}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"予期しないエラー: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
