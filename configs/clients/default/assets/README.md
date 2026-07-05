# Default client assets

Placeholder directory. Real binary assets (app icon, launch logo, splash background) referenced by `app.json` are added when the white-label build pipeline is implemented (Phase 5) and when real branding is supplied. Paths are reserved now so `app.json` validates and the pipeline's asset-copy step has a stable contract to target:

- `assets/app-icon.png`
- `assets/launch-logo.png`
- `assets/splash-background.png`
