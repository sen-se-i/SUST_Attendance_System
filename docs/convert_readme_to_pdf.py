import os
import re
import html
import subprocess
import base64

def image_to_base64(img_path):
    if os.path.exists(img_path):
        ext = os.path.splitext(img_path)[1].lower().replace('.', '')
        if ext == 'jpg': ext = 'jpeg'
        with open(img_path, 'rb') as f:
            b64 = base64.b64encode(f.read()).decode('utf-8')
            return f"data:image/{ext};base64,{b64}"
    return img_path

def md_to_html(md_text, base_dir):
    # Process images: ![alt](path)
    def repl_img(match):
        alt = match.group(1)
        src = match.group(2)
        local_path = os.path.normpath(os.path.join(base_dir, src))
        b64_src = image_to_base64(local_path)
        return f'<div class="img-container"><img src="{b64_src}" alt="{alt}"/><div class="img-caption">{alt}</div></div>'

    lines = md_text.split('\n')
    html_lines = []
    in_code_block = False
    code_block_lang = ''
    code_block_content = []
    in_table = False
    table_rows = []

    def flush_table():
        nonlocal in_table, table_rows, html_lines
        if not table_rows:
            return
        
        # parse table
        out = ['<table class="md-table">']
        # header
        headers = [c.strip() for c in table_rows[0].strip('|').split('|')]
        out.append('<thead><tr>')
        for h in headers:
            out.append(f'<th>{inline_format(h)}</th>')
        out.append('</tr></thead><tbody>')
        
        for row in table_rows[2:]: # skip separator
            cells = [c.strip() for c in row.strip('|').split('|')]
            out.append('<tr>')
            for c in cells:
                out.append(f'<td>{inline_format(c)}</td>')
            out.append('</tr>')
        out.append('</tbody></table>')
        html_lines.append('\n'.join(out))
        table_rows = []
        in_table = False

    def inline_format(text):
        # Escape html basic
        # Code: `code`
        text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
        # Bold: **bold**
        text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
        # Italic: *italic*
        text = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', text)
        # Links: [text](url)
        text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)
        # Images: ![alt](url)
        text = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', repl_img, text)
        # Math: $$...$$ or $...$
        # Let KaTeX or MathJax or CSS handle it
        return text

    i = 0
    while i < len(lines):
        line = lines[i]

        # Code block check
        if line.strip().startswith('```'):
            if in_table:
                flush_table()
            if in_code_block:
                # close code block
                content = html.escape('\n'.join(code_block_content))
                if code_block_lang == 'mermaid':
                    html_lines.append(f'<div class="mermaid">\n{chr(10).join(code_block_content)}\n</div>')
                else:
                    html_lines.append(f'<pre><code class="language-{code_block_lang}">{content}</code></pre>')
                in_code_block = False
                code_block_content = []
                code_block_lang = ''
            else:
                in_code_block = True
                code_block_lang = line.strip()[3:].strip()
            i += 1
            continue

        if in_code_block:
            code_block_content.append(line)
            i += 1
            continue

        # Table row check
        if line.strip().startswith('|') and line.strip().endswith('|'):
            in_table = True
            table_rows.append(line.strip())
            i += 1
            continue
        elif in_table:
            flush_table()

        # Blank line
        if not line.strip():
            html_lines.append('<div class="spacer"></div>')
            i += 1
            continue

        # Horizontal rule
        if line.strip() in ['---', '***', '___']:
            html_lines.append('<hr/>')
            i += 1
            continue

        # Headings
        if line.startswith('# '):
            html_lines.append(f'<h1>{inline_format(line[2:])}</h1>')
            i += 1
            continue
        elif line.startswith('## '):
            html_lines.append(f'<h2>{inline_format(line[3:])}</h2>')
            i += 1
            continue
        elif line.startswith('### '):
            html_lines.append(f'<h3>{inline_format(line[4:])}</h3>')
            i += 1
            continue
        elif line.startswith('#### '):
            html_lines.append(f'<h4>{inline_format(line[5:])}</h4>')
            i += 1
            continue

        # Image standalone
        img_match = re.match(r'^!\[([^\]]*)\]\(([^)]+)\)$', line.strip())
        if img_match:
            html_lines.append(repl_img(img_match))
            i += 1
            continue

        # Math display: $$...$$
        if line.strip().startswith('$$') and line.strip().endswith('$$'):
            html_lines.append(f'<div class="math-display">{html.escape(line.strip())}</div>')
            i += 1
            continue

        # Unordered list: * or -
        if re.match(r'^\s*[\*\-]\s+', line):
            indent = len(line) - len(line.lstrip())
            item_text = re.sub(r'^\s*[\*\-]\s+', '', line)
            html_lines.append(f'<li style="margin-left: {indent*10}px;">{inline_format(item_text)}</li>')
            i += 1
            continue

        # Ordered list: 1. or 2.
        num_match = re.match(r'^\s*(\d+)\.\s+(.*)$', line)
        if num_match:
            indent = len(line) - len(line.lstrip())
            item_text = num_match.group(2)
            num = num_match.group(1)
            html_lines.append(f'<div class="numbered-item" style="margin-left: {indent*10}px;"><span class="num">{num}.</span> {inline_format(item_text)}</div>')
            i += 1
            continue

        # Paragraph
        html_lines.append(f'<p>{inline_format(line)}</p>')
        i += 1

    if in_table:
        flush_table()

    return '\n'.join(html_lines)

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    readme_path = os.path.join(base_dir, 'README.md')
    html_out_path = os.path.join(base_dir, 'README_print.html')
    pdf_out_path = os.path.join(base_dir, 'README.pdf')

    with open(readme_path, 'r', encoding='utf-8') as f:
        md_content = f.read()

    body_html = md_to_html(md_content, base_dir)

    full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>SWE Attendance System - Documentation</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
<script>
  mermaid.initialize({{ startOnLoad: true, theme: 'default' }});
</script>
<style>
  @page {{
    size: A4;
    margin: 15mm 15mm 15mm 15mm;
  }}
  @media print {{
    body {{
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }}
    .page-break {{
      page-break-before: always;
    }}
    h1, h2, h3 {{
      page-break-after: avoid;
    }}
    table, pre, .img-container {{
      page-break-inside: avoid;
    }}
  }}

  * {{
    box-sizing: border-box;
  }}

  body {{
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    color: #1f2937;
    background-color: #ffffff;
    line-height: 1.6;
    font-size: 13px;
    padding: 0;
    margin: 0;
  }}

  h1 {{
    font-size: 24px;
    font-weight: 800;
    color: #0f172a;
    border-bottom: 2px solid #e2e8f0;
    padding-bottom: 8px;
    margin-top: 20px;
    margin-bottom: 12px;
  }}

  h2 {{
    font-size: 18px;
    font-weight: 700;
    color: #1e293b;
    border-bottom: 1px solid #e2e8f0;
    padding-bottom: 6px;
    margin-top: 24px;
    margin-bottom: 12px;
  }}

  h3 {{
    font-size: 15px;
    font-weight: 600;
    color: #334155;
    margin-top: 18px;
    margin-bottom: 8px;
  }}

  h4 {{
    font-size: 13px;
    font-weight: 600;
    color: #475569;
    margin-top: 14px;
    margin-bottom: 6px;
  }}

  p {{
    margin: 6px 0;
  }}

  hr {{
    border: none;
    border-top: 1px solid #e2e8f0;
    margin: 18px 0;
  }}

  code {{
    font-family: 'JetBrains Mono', 'Fira Code', Consolas, monospace;
    background-color: #f1f5f9;
    color: #0f172a;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 11.5px;
    border: 1px solid #e2e8f0;
  }}

  pre {{
    font-family: 'JetBrains Mono', 'Fira Code', Consolas, monospace;
    background-color: #0f172a;
    color: #f8fafc;
    padding: 12px 14px;
    border-radius: 6px;
    font-size: 11px;
    line-height: 1.45;
    overflow-x: auto;
    margin: 10px 0;
  }}

  pre code {{
    background-color: transparent;
    color: inherit;
    padding: 0;
    border: none;
    font-size: inherit;
  }}

  table.md-table {{
    width: 100%;
    border-collapse: collapse;
    margin: 12px 0;
    font-size: 12px;
  }}

  table.md-table th {{
    background-color: #f8fafc;
    color: #1e293b;
    font-weight: 600;
    text-align: left;
    padding: 8px 10px;
    border: 1px solid #cbd5e1;
  }}

  table.md-table td {{
    padding: 7px 10px;
    border: 1px solid #e2e8f0;
    vertical-align: top;
  }}

  table.md-table tr:nth-child(even) {{
    background-color: #f8fafc;
  }}

  .img-container {{
    text-align: center;
    margin: 14px 0;
  }}

  .img-container img {{
    max-width: 100%;
    height: auto;
    border-radius: 6px;
    border: 1px solid #e2e8f0;
    box-shadow: 0 2px 6px rgba(0,0,0,0.05);
  }}

  .img-caption {{
    font-size: 11px;
    color: #64748b;
    margin-top: 4px;
    font-style: italic;
  }}

  .math-display {{
    background-color: #f8fafc;
    border-left: 3px solid #3b82f6;
    padding: 8px 12px;
    margin: 8px 0;
    border-radius: 0 4px 4px 0;
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
  }}

  li {{
    margin-bottom: 4px;
  }}

  .numbered-item {{
    margin-bottom: 6px;
  }}

  .numbered-item .num {{
    font-weight: 600;
    color: #2563eb;
  }}

  .spacer {{
    height: 4px;
  }}

  a {{
    color: #2563eb;
    text-decoration: none;
  }}

  .mermaid {{
    display: flex;
    justify-content: center;
    background: #ffffff;
    padding: 12px;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    margin: 10px 0;
  }}
</style>
</head>
<body>
{body_html}
</body>
</html>"""

    with open(html_out_path, 'w', encoding='utf-8') as f:
        f.write(full_html)

    print(f"Generated HTML at {html_out_path}")

    # Edge headless command
    edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    cmd = [
        edge_path,
        "--headless",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        "--virtual-time-budget=5000",
        f"--print-to-pdf={pdf_out_path}",
        "--no-pdf-header-footer",
        html_out_path
    ]
    print("Running Edge to produce PDF...")
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode == 0 and os.path.exists(pdf_out_path):
        print(f"Successfully created PDF: {pdf_out_path} (Size: {os.path.getsize(pdf_out_path)} bytes)")
    else:
        print(f"Edge conversion failed or returned: {res.returncode}, stderr: {res.stderr}")

if __name__ == "__main__":
    main()
