---
description: Convert a markdown file to a clean PDF. Usage: /md-to-pdf <path-to-file.md>
---

# Markdown to PDF

Convert a markdown file to a well-formatted PDF using pandoc + tectonic.

## Arguments

$ARGUMENTS — the path to the markdown file to convert. If no path is provided, ask the user.

## Process

1. Resolve the input file path from `$ARGUMENTS`. If the path is relative, resolve it against the current working directory.
2. Derive the output path by replacing the `.md` extension with `.pdf` in the same directory.
3. Run the conversion:

```bash
pandoc "<input_file>" \
  --pdf-engine=tectonic \
  -V geometry:margin=2.5cm \
  -V colorlinks=true \
  -V linkcolor=NavyBlue \
  -V urlcolor=NavyBlue \
  -V mainfont="Helvetica Neue" \
  -V monofont="Menlo" \
  --highlight-style=tango \
  -o "<output_file>"
```

4. If pandoc or tectonic are not installed, install them:
   - `brew install pandoc tectonic`

5. Report the output path and file size. Offer to open it with `open "<output_file>"`.

## Notes

- If there are Unicode warnings about missing characters (≥, €, etc.), add `--pdf-engine=xelatex` or preprocess the markdown to replace problematic characters with LaTeX equivalents.
- For tables that overflow the page width, consider adding `-V geometry:margin=1.5cm` to reduce margins.
- The output PDF is placed alongside the source markdown file by default.
