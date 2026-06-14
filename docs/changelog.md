# Changelog

## 0.3 — 2026-06-14

Gjort kompletterande migreringskontroll mot kvarvarande gamla dokument i `home-assistant/docs/rain-observatory` och flyttat över unikt innehåll som inte tidigare var fullt representerat.

Tillagt:

```text
docs/decisions.md
docs/vision/national-rain-observation-platform.md
```

Uppdaterat:

```text
docs/sources.md
docs/glossary.md
mkdocs.yml
```

Huvudbeslut:

- beslutsloggen finns nu i den nya strukturen,
- visionen om en framtida svensk regnobservationsplattform finns nu i den nya strukturen,
- källregistret är migrerat i mer komplett form,
- begreppslistan är migrerad i mer komplett form,
- `hydromet-docs` är nu mycket nära komplett informationsmässigt jämfört med den gamla regnobservatorie-dokumentationen.

## 0.2 — 2026-06-14

Migrerat resterande centrala beslut och detaljer från tidigare `home-assistant/docs/rain-observatory` utan att kräva exakt 1:1-struktur.

Tillagt:

```text
docs/architecture/rain-architecture-details.md
docs/architecture/rain-data-model-details.md
docs/modules/rain-analysis-modules.md
docs/adr/adr-0002-logger-test-is-permanent.md
docs/adr/adr-0003-netatmo-cloud-is-interval-series.md
docs/adr/adr-0004-no-forward-extrapolation.md
docs/adr/adr-0005-local-idf-long-term-goal.md
docs/adr/adr-0006-asymmetric-gauge-health-checks.md
docs/adr/adr-0007-climate-predictor-idf-is-future-method.md
```

Uppdaterat:

```text
mkdocs.yml
```

Huvudbeslut:

- dokumentationen behöver inte vara exakt 1:1 med gamla strukturen,
- informationen ska däremot inte tappas,
- detaljer om regnarkitektur, konceptuell datamodell och analysmoduler finns nu i egna detaljdokument,
- samtliga tidigare ADR-0001 till ADR-0008 finns nu i `hydromet-docs`.

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
