# Changelog

## 0.1 — 2026-06-14

Initierat `hydromet-docs` som separat dokumentationsrepo.

Tillagt:

```text
README.md
mkdocs.yml
docs/index.md
docs/architecture/overview.md
docs/architecture/hydromet-core-model.md
docs/architecture/observation-domains.md
docs/architecture/sql-plan.md
docs/architecture/mqtt-message-contract.md
docs/architecture/system-health.md
docs/modules/rain-observatory.md
docs/modules/climate-predictor-idf.md
docs/modules/skyfall-mapping-context.md
docs/roadmap.md
docs/sources.md
docs/glossary.md
docs/adr/adr-0001-raw-data-is-sacred.md
docs/adr/adr-0008-hydromet-core-before-rain-module.md
```

Huvudbeslut:

- hydromet-docs blir hem för metod, arkitektur, datamodell, källor och långsiktig dokumentation,
- home-assistant-repot fortsätter vara implementation och driftmiljö,
- regnobservatoriet är första modul ovanpå en generell hydromet-kärna,
- nya dataklasser ska kunna läggas till utan ny grundarkitektur.
