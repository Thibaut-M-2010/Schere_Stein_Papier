# Release Notes (Draft)

Version: v1.0.0-test

Summary
- Small test release to validate Windows packaging and CI.

Included
- App image / installer artifacts produced by GitHub Actions Windows runner.

How to trigger CI
- Create and push an annotated tag locally:
  - `git tag -a v1.0.0-test -m "Test Windows release"`
  - `git push origin v1.0.0-test`
- Or run the Windows workflow manually via the Actions page (select `build-release-windows` and `Run workflow`).

Where to find artifacts
- Actions will upload `installer/**` and attach installers to the Release. Expect filenames like:
  - `SchereSteinPapier-<version>.exe` (if WiX available on runner)
  - `SchereSteinPapier-appimage.zip` (app image fallback)

Signing
- To enable automatic signing in CI, add these GitHub Secrets:
  - `SIGN_PFX_B64` (base64 of your .pfx)
  - `SIGN_PFX_PASSWORD`

Notes for maintainers
- This repo now ignores `dist/`, `installer/`, and compiled `.class` files via `.gitignore`.
- If you want me to prepare a Release body and attach the produced artifacts, tell me the tag name and whether signing is required.
