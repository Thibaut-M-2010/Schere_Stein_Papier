from PIL import Image, ImageDraw
import os

# Erstelle das images-Verzeichnis, wenn es nicht existiert
os.makedirs("images", exist_ok=True)

# Stein (Faust)
img_stein = Image.new('RGB', (200, 200), color='white')
draw = ImageDraw.Draw(img_stein)
draw.ellipse([10, 10, 190, 190], outline='black', width=3)
# Faust zeichnen
draw.ellipse([70, 60, 130, 120], outline='black', width=2)
draw.line([85, 80, 80, 50], fill='black', width=2)
img_stein.save("images/stein.png")

# Papier (offene Hand)
img_papier = Image.new('RGB', (200, 200), color='white')
draw = ImageDraw.Draw(img_papier)
draw.ellipse([10, 10, 190, 190], outline='black', width=3)
# Offene Hand zeichnen
draw.ellipse([75, 85, 125, 135], outline='black', width=2)
for i in range(4):
    x = 85 + i * 10
    draw.line([x, 85, x, 40], fill='black', width=2)
draw.line([70, 100, 50, 130], fill='black', width=2)
img_papier.save("images/papier.png")

# Schere (Victory-Zeichen)
img_schere = Image.new('RGB', (200, 200), color='white')
draw = ImageDraw.Draw(img_schere)
draw.ellipse([10, 10, 190, 190], outline='black', width=3)
# V-Zeichen
draw.line([100, 90, 75, 140], fill='black', width=3)
draw.line([100, 90, 125, 140], fill='black', width=3)
draw.line([95, 110, 85, 95], fill='black', width=2)
img_schere.save("images/schere.png")

print("PNG-Dateien erstellt!")
