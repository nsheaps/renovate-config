# JSON5 to JSON Conversion

The `default.json` file is generated from `default.json5` by CI.

**DO NOT** manually regenerate `default.json` locally. The sync-json workflow (`.github/workflows/sync-json.yml`) handles this automatically when changes are pushed to main.

When making changes:
1. Edit `default.json5` (the source of truth)
2. Commit and push to main
3. CI will auto-generate and commit `default.json`

The workflow runs `npx json5 default.json5 | jq '.' > default.json` followed by biome formatting.
