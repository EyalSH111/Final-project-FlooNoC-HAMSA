from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parent
MD_PATH = ROOT / "HAMSA_FlooNoC_Full_Integration_Report.md"
DOCX_PATH = ROOT / "HAMSA_FlooNoC_Full_Integration_Report.docx"


def text_runs(text: str, style: str | None = None) -> str:
    text = escape(text)
    if style == "code":
        return (
            "<w:r><w:rPr><w:rFonts w:ascii=\"Courier New\" w:hAnsi=\"Courier New\"/>"
            "<w:sz w:val=\"18\"/></w:rPr><w:t xml:space=\"preserve\">"
            f"{text}</w:t></w:r>"
        )
    if style == "bold":
        return f"<w:r><w:rPr><w:b/></w:rPr><w:t xml:space=\"preserve\">{text}</w:t></w:r>"
    return f"<w:r><w:t xml:space=\"preserve\">{text}</w:t></w:r>"


def paragraph(text: str = "", pstyle: str | None = None, rstyle: str | None = None) -> str:
    ppr = f"<w:pPr><w:pStyle w:val=\"{pstyle}\"/></w:pPr>" if pstyle else ""
    return f"<w:p>{ppr}{text_runs(text, rstyle)}</w:p>"


def parse_markdown(md: str) -> list[str]:
    body: list[str] = []
    in_code = False
    code_lines: list[str] = []

    def flush_code() -> None:
        nonlocal code_lines
        if not code_lines:
            return
        for line in code_lines:
            body.append(paragraph(line, "Code", "code"))
        code_lines = []

    for raw_line in md.splitlines():
        line = raw_line.rstrip()
        if line.startswith("```"):
            if in_code:
                flush_code()
                in_code = False
            else:
                in_code = True
            continue

        if in_code:
            code_lines.append(line)
            continue

        if line.startswith("# "):
            body.append(paragraph(line[2:].strip(), "Title"))
        elif line.startswith("## "):
            body.append(paragraph(line[3:].strip(), "Heading1"))
        elif line.startswith("### "):
            body.append(paragraph(line[4:].strip(), "Heading2"))
        elif line.startswith("- "):
            body.append(paragraph(line[2:].strip(), "ListParagraph"))
        elif not line:
            body.append(paragraph(""))
        else:
            body.append(paragraph(line))

    flush_code()
    return body


def make_document_xml(body_parts: list[str]) -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        "<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">"
        "<w:body>"
        + "".join(body_parts)
        + "<w:sectPr><w:pgSz w:w=\"12240\" w:h=\"15840\"/><w:pgMar w:top=\"1440\" "
        "w:right=\"1440\" w:bottom=\"1440\" w:left=\"1440\" w:header=\"720\" "
        "w:footer=\"720\" w:gutter=\"0\"/></w:sectPr></w:body></w:document>"
    )


STYLES_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:rPr><w:sz w:val="22"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:rPr><w:b/><w:sz w:val="36"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:rPr><w:b/><w:sz w:val="30"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:rPr><w:b/><w:sz w:val="26"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ListParagraph">
    <w:name w:val="List Paragraph"/>
    <w:pPr><w:ind w:left="720"/></w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Code">
    <w:name w:val="Code"/>
    <w:pPr><w:spacing w:before="0" w:after="0"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/><w:sz w:val="18"/></w:rPr>
  </w:style>
</w:styles>
"""


CONTENT_TYPES = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
"""


RELS = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"""


DOC_RELS = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
"""


def main() -> None:
    md = MD_PATH.read_text(encoding="utf-8")
    document_xml = make_document_xml(parse_markdown(md))
    with ZipFile(DOCX_PATH, "w", ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", CONTENT_TYPES)
        zf.writestr("_rels/.rels", RELS)
        zf.writestr("word/_rels/document.xml.rels", DOC_RELS)
        zf.writestr("word/styles.xml", STYLES_XML)
        zf.writestr("word/document.xml", document_xml)
    print(DOCX_PATH)


if __name__ == "__main__":
    main()
