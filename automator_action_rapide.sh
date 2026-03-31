#log
LOGFILE="$HOME/automator.log"
exec >> "$LOGFILE" 2>&1
 
echo "==== $(date) ===="
set -x

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"


# Installer les dépendances si nécessaire
/usr/bin/python3 -c "import pypdf, reportlab" 2>/dev/null || \
/usr/bin/python3 -m pip install pypdf reportlab --quiet

GS_PATH=$(which gs)

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP_PATH="$BASE_DIR/img/tampon.png"

if [ -z "$GS_PATH" ]; then
    echo "GhostScript n'est pas installé !"
    exit 1
fi

echo "GhostScript trouvé à $GS_PATH"

OUTPUT_DIR="./Documents tamponnés"
echo "Création du répertoire de destination..."
mkdir -p "$OUTPUT_DIR"

for input in "$@"; do

    echo "🕙 Traitement de $input..."

    original_name="$(basename "$input" .pdf)"
    output_path="$OUTPUT_DIR/${original_name}_tamponné.pdf"

/usr/bin/python3 - "$input" "$output_path" "$original_name" "$GS_PATH" "$STAMP_PATH"<< 'PYEOF'

import sys, io, base64, subprocess
from reportlab.lib.utils import ImageReader
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas

#attributions des params

input_path = sys.argv[1]
output_path = sys.argv[2]
doc_name = sys.argv[3]
gs_path = sys.argv[4]
image_path = sys.argv[5]

#traitement base64

stamp_image = ImageReader(image_path)

#  Normalisation PDF via Ghostscript directement en mémoire

gs_cmd = [
    gs_path, "-q", "-dNOPAUSE", "-dBATCH", "-sDEVICE=pdfwrite",
    "-dAutoRotatePages=/None", "-sOutputFile=-", input_path
]
gs_proc = subprocess.run(gs_cmd, stdout=subprocess.PIPE, check=True)
pdf_bytes = io.BytesIO(gs_proc.stdout)

reader = PdfReader(pdf_bytes)
writer = PdfWriter()

first_page = reader.pages[0]
page_width = float(first_page.mediabox.width)
page_height = float(first_page.mediabox.height)

stamp_size = 200
margin = 8

dx = 60   # déplacer à droite (+) / gauche (-)
dy = -10   # déplacer vers le haut (-) / vers le bas (+)

cx = page_width - stamp_size / 2 - margin + dx
cy = page_height - stamp_size / 2 - margin + dy

#stamping   

overlay_packet = io.BytesIO()
c = canvas.Canvas(overlay_packet, pagesize=(page_width, page_height))
c.drawImage(
    stamp_image,
    cx - stamp_size / 2,
    cy - stamp_size / 2,
    width=stamp_size,
    height=stamp_size,
    mask='auto',
)

    # Ajout du numéro au centre
font_size_num = max(3, stamp_size * 0.09)
c.setFont("Helvetica-Bold", font_size_num)

    # dessin numéro au centre
c.drawCentredString(cx - font_size_num * 0.3, cy - font_size_num * -2.5, doc_name)
c.save()
overlay_packet.seek(0)

first_page.merge_page(PdfReader(overlay_packet).pages[0])
writer.add_page(first_page)

with open(output_path, "wb") as f:
    writer.write(f)

PYEOF

    if [ $? -eq 0 ]; then
        echo "✅ $original_name : opération réussie, fichier créé dans $output_path"
    else
        echo "❌ $original_name : erreur pendant le traitement !" >&2
        continue
    fi

done