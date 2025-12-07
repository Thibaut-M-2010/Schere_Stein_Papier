from PIL import Image
import os

# Erstelle das images Verzeichnis falls es nicht existiert
images_dir = "src/images"
os.makedirs(images_dir, exist_ok=True)

# Deine Bilder - basierend auf der Reihenfolge in deinen Anhängen
# 1. Papier (offene Hand)
# 2. Stein (Faust)
# 3. Schere (V-Zeichen)

print(f"Images-Verzeichnis: {os.path.abspath(images_dir)}")
print("Die PNG-Dateien sollten jetzt verwendet werden.")
