## Getting Started

Welcome to the VS Code Java world. Here is a guideline to help you get started to write Java code in Visual Studio Code.

## Folder Structure

 # SchereSteinPapierGUI — Projektübersicht

Kurze Anleitung zur Entwicklung, Verpackung und Veröffentlichung.

## Getting Started

- Quellcode: `src`
- Build: Maven (`pom.xml`) — Java 17
- Laufzeitklassen (optional): `bin`, Ausgaben: `dist`, Installer: `installer`

Kompilieren und lokal starten (wenn JDK installiert):

```powershell
javac -d bin -sourcepath src src\App.java
java -cp bin App
```

## Packaging & Installer (jpackage)

Ein PowerShell-Skript erstellt native Installer (Windows EXE, Linux DEB, macOS DMG) per `jpackage`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package-with-jpackage.ps1 -EmbedRuntime -IconPath ".\resources\favicon.ico"
```

Das Skript unterstützt:
- `-EmbedRuntime` — erstellt ein schlankes Laufzeitimage via `jlink` und bindet es ein
- `-BundleJavaFX -JavaFXVersion <ver>` — lädt optional OpenJFX SDK und bindet JavaFX-Module ein
- `-Type <exe|deb|dmg>` — legt den Pakettyp fest (wird automatisch durch CI-Matrix gesetzt)

Erzeugte Installer landen im Ordner `installer/`.

## Release Checklist (Kurz)

Vor dem Erstellen eines GitHub Release-Tags:

- Stelle sicher, dass `mvn -DskipTests package` lokal läuft und ein JAR erzeugt.
- Führe das Packaging-Skript lokal aus und teste den Installer (`installer/`).
- Lege `resources\favicon.ico` an, wenn du ein Icon möchtest.
- Optional: füge `SIGN_PFX_B64` und `SIGN_PFX_PASSWORD` als GitHub Secrets hinzu, damit CI Windows-EXEs signiert.
- Optional: füge `RELEASE_TOKEN` (PAT) hinzu, wenn ein bestimmtes Konto Releases erstellen soll.

Empfehlung: zuerst einen Test-Tag wie `v1.0.0-test` pushen, um den CI‑Durchlauf zu prüfen.

## **Windows Release**

- **Local Build:** Run `mvn -DskipTests package` to create the JAR in `target/`.
- **Run Packager Locally:** On Windows (JDK 17+, `jpackage` available) run:
	- `powershell -ExecutionPolicy Bypass -File .\scripts\package-windows-only.ps1 -IconPath '.\resources\favicon.ico'`
	- This script expects the built JAR copied to `dist\SchereSteinPapier.jar` (the CI workflow copies it automatically). If you prefer to leave the JAR in `target/`, copy it to `dist` first.
- **Signing Locally (optional):** Use `signtool.exe` if you have a PFX certificate:
	- `signtool sign /f path\to\cert.pfx /p YourPassword /tr http://timestamp.digicert.com /td sha256 /fd sha256 path\to\installer\SchereSteinPapier-*.exe`

- **Prepare PFX for CI (optional):** Create Base64 of your `.pfx` for a GitHub secret on Windows:
	- `Get-Content -Path 'C:\path\to\cert.pfx' -Encoding Byte -ReadCount 0 | [System.Convert]::ToBase64String(($_)) > cert.pfx.b64`
	- Then copy the contents of `cert.pfx.b64` into the GitHub secret `SIGN_PFX_B64` and set `SIGN_PFX_PASSWORD` to the certificate password.

- **CI / GitHub Actions:** The Windows-only workflow file is `.github/workflows/build-release-windows.yml`.
	- To trigger the workflow and produce an installer, push a tag:
		- `git tag -a v1.0.0-test -m "Test Windows release"`
		- `git push origin --tags`
	- Or use the `workflow_dispatch` button on the Actions page to run it manually.

- **Secrets for automatic signing (optional):**
	- `SIGN_PFX_B64` — base64-encoded PFX contents (set as a secret).
	- `SIGN_PFX_PASSWORD` — password for the PFX file.
	- If both are set, the packaging script will attempt to decode the PFX and run `signtool.exe` on produced EXE files in the `installer/` folder.

- **Troubleshooting:**
	- If the workflow fails complaining about `mvn` or missing JAR, ensure the Maven build step completed and the JAR exists under `dist/` or `target/` before packaging.
	- If `jpackage` is missing locally, install JDK 17+ that includes `jpackage`.

## **Web & Android (new)**

I added a lightweight browser version of the game in `web/` and a tiny Node WebSocket relay you can run for multiplayer testing.

- `web/index.html`, `web/app.js`, `web/style.css`: a minimal single-page Rock-Paper-Scissors app with:
	- Start screen: choose `Play vs Computer` or `Multiplayer`.
	- Multiplayer: `Create` generates a 6-character join code; `Join` accepts a code to join.
	- Multiplayer transport: simple WebSocket relay server (below) — clients exchange moves via the server.

- `scripts/signaling-server.js` and `scripts/signaling-server-package.json`: a small Node WebSocket server (uses `ws`). Run locally for testing:

```powershell
cd scripts
npm install --no-audit --no-fund
node signaling-server.js
```

The client defaults to `ws://localhost:8080` when loaded from `localhost`. If you host the signaling server remotely, open `web/index.html` in the browser and it will attempt to connect to the server at the same origin.

Android APK / WebView
- You can wrap the `web/` folder in a Cordova or Capacitor project to produce an Android APK. Quick outline (Cordova):

```powershell
# install cordova
# npm install -g cordova
# cordova create myapp
# copy web/ contents into myapp/www/
# cd myapp
# cordova platform add android
# cordova build android
```

Notes & limitations
- The signaling server is a simple relay for two-player rooms; it is intended for quick testing or self-hosting. For public deployment you should run the server on a public host (Heroku, Railway, VPS) and enable TLS (wss://).
- The Android wrapper just loads the web app in a WebView and will work with the WebSocket server if reachable.

### Quick helpers added

- `scripts/run-signaling-server.ps1` — helper to install dependencies and run the signaling server locally. Run this on a machine with Node.js:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-signaling-server.ps1
```

- `scripts/create-cordova.ps1` — scaffolds a Cordova Android project under `scripts/cordova-app` and copies `web/` into the Cordova `www/` folder. Usage (run locally with Cordova CLI installed):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create-cordova.ps1 -AppId "com.yourdomain.ssp" -AppName "SchereSteinPapierMobile"
# then
cd scripts/cordova-app
cordova build android
```

After `cordova build android` completes you will find the APK under `scripts/cordova-app/platforms/android/app/build/outputs/apk/` (depending on Cordova / Android tooling versions).

If you prefer Capacitor, let me know and I can add a Capacitor scaffold instead.



## macOS: Codesign & Notarize (Überblick)

Für macOS-Distributionen sind zusätzliche Schritte nötig:

1. Besorge ein Developer ID Application Zertifikat (Apple Developer) und installiere es in deinem macOS Keychain oder exportiere Schlüssel für `notarytool`.
2. Codesigne das `.app`-Bundle:

```bash
codesign --deep --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" /path/to/YourApp.app
```

3. Erzeuge ein DMG und reiche es bei Apple zur Notarisierung ein (z. B. `notarytool`):

```bash
xcrun notarytool submit /path/to/YourApp.dmg --key yourkey.json --team-id TEAMID --wait
xcrun stapler staple /path/to/YourApp.dmg
```

Automatisierung: macOS Runner + sichere Apple API Keys sind erforderlich. Sag mir Bescheid, wenn du ein Notarization-Template in der Workflow-Datei möchtest.

## CI / GitHub Actions Hinweise

- Die Workflow-Datei in `.github/workflows/` verwendet eine Matrix (Windows/Linux/macOS), baut die JAR, führt das Packaging-Skript aus und lädt die erzeugten Installer-Artefakte hoch.
- Auf Tag-Pushes bundelt die Action standardmäßig JavaFX (falls aktiviert) und erstellt eine Release mit den Artefakten.
- Für automatische Windows-Signaturen: setze `SIGN_PFX_B64` + `SIGN_PFX_PASSWORD` als Secrets; `signtool.exe` muss im Runner verfügbar sein.

## Tags / Release auslösen

Tag pushen (lokal -> remote):

```powershell
git tag v1.0.0
git push origin v1.0.0
```

Oder manuell per `workflow_dispatch` in den Actions auf GitHub starten.

---

Wenn du möchtest, erstelle ich gern ein Notarization-Template für macOS oder ergänze die Workflow-Datei um detaillierte Codesign-/Notarize-Schritte.


