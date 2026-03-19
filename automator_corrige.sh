#!/bin/bash

export PYTHONPATH="/Users/charlessaunier/Library/Python/3.9/lib/python/site-packages:$PYTHONPATH"

/Library/Developer/CommandLineTools/usr/bin/python3 << 'PYEOF' "$@"
import sys, io, os, math

args = sys.argv[1:]

sys.path.insert(0, "/Users/charlessaunier/Library/Python/3.9/lib/python/site-packages")

try:
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfgen import canvas
    from reportlab.lib import colors
except ImportError as e:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pypdf", "reportlab", "--user", "-q"])
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfgen import canvas
    from reportlab.lib import colors


def draw_stamp(c, cx, cy, doc_name, stamp_size=60):
    r = stamp_size / 2 - 2
    r_inner = r - 7
    arc_r = (r + r_inner) / 2

    c.setFillColor(colors.white)
    c.circle(cx, cy, r + 2, stroke=0, fill=1)
    c.setStrokeColor(colors.black)
    c.setFillColor(colors.black)
    c.setLineWidth(1.5)
    c.circle(cx, cy, r, stroke=1, fill=0)
    c.setLineWidth(0.8)
    c.circle(cx, cy, r_inner, stroke=1, fill=0)

    top_text = "ENJEA AVOCATS"
    start_angle, end_angle = 25, 155
    char_span = (end_angle - start_angle) / (len(top_text) - 1)
    font_size_top = max(3.5, stamp_size * 0.075)
    c.setFont("Helvetica-Bold", font_size_top)
    for i, ch in enumerate(top_text):
        angle_deg = end_angle - i * char_span
        angle_rad = math.radians(angle_deg)
        x = cx + arc_r * math.cos(angle_rad)
        y = cy + arc_r * math.sin(angle_rad)
        c.saveState(); c.translate(x, y); c.rotate(angle_deg - 90)
        c.drawCentredString(0, 0, ch); c.restoreState()

    bottom_text = "SCP D'Avocats du Barreau de Paris"
    start_b, end_b = 205, 335
    char_span_b = (end_b - start_b) / (len(bottom_text) - 1)
    font_size_bot = max(2.5, stamp_size * 0.048)
    c.setFont("Helvetica", font_size_bot)
    for i, ch in enumerate(bottom_text):
        angle_deg = start_b + i * char_span_b
        angle_rad = math.radians(angle_deg)
        x = cx + arc_r * math.cos(angle_rad)
        y = cy + arc_r * math.sin(angle_rad)
        c.saveState(); c.translate(x, y); c.rotate(angle_deg + 90)
        c.drawCentredString(0, 0, ch); c.restoreState()

    font_size_label = max(4, stamp_size * 0.09)
    c.setFont("Helvetica", font_size_label)
    c.drawCentredString(cx, cy + r_inner * 0.28, "Pièce")

    font_size_num = max(7, stamp_size * 0.22)
    c.setFont("Helvetica-Bold", font_size_num)
    c.drawCentredString(cx, cy - font_size_num * 0.3, doc_name)

    font_size_n = max(3.5, stamp_size * 0.075)
    c.setFont("Helvetica", font_size_n)
    c.drawString(cx - r_inner * 0.55, cy - r_inner * 0.5, "N°")


def stamp_pdf(input_path, output_path, doc_name):
    reader = PdfReader(input_path)
    writer = PdfWriter()
    first_page = reader.pages[0]
    page_width = float(first_page.mediabox.width)
    page_height = float(first_page.mediabox.height)
    stamp_size = 60
    margin = 8
    cx = page_width - stamp_size / 2 - margin
    cy = page_height - stamp_size / 2 - margin
    for i, page in enumerate(reader.pages):
        if i == 0:
            overlay_packet = io.BytesIO()
            c = canvas.Canvas(overlay_packet, pagesize=(page_width, page_height))
            draw_stamp(c, cx, cy, doc_name, stamp_size)
            c.save()
            overlay_packet.seek(0)
            page.merge_page(PdfReader(overlay_packet).pages[0])
        writer.add_page(page)
    with open(output_path, "wb") as f:
        writer.write(f)


for path in args:
    if path.lower().endswith(".pdf"):
        base = os.path.splitext(os.path.basename(path))[0]
        folder = os.path.dirname(path)
        output_path = os.path.join(folder, base + "_tamponné.pdf")
        stamp_pdf(path, output_path, base)

PYEOF
