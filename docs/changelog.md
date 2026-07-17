# Changelog

## 0.6 — 2026-07-17

Dokumenterat och korrigerat den permanenta parallella test- och produktionsingesten för verkliga Nimbus.

Tillagt:

```text
docs/architecture/nimbus-parallel-ingest.md
docs/runbooks/nimbus-parallel-ingest.md
docs/adr/adr-0011-nimbus-parallel-test-production-ingest.md
sql/hydromet/004_seed_nimbus_series.sql
sql/hydromet/verify_nimbus_parallel_storage.sql
```

Uppdaterat:

```text
sql/hydromet/002_event_observation_dedup.sql
sql/hydromet/003_rain_logger_test_events.sql
docs/adr/adr-0009-separate-logger-test-from-analysis-test.md
docs/decisions.md
mkdocs.yml
```

Huvudkorrigeringar och beslut:

- arbetet gäller verkliga Nimbus och är helt separat från den äldre syntetiska `logger_test`-kedjan och `public.*`,
- Nimbus har ett permanent testmål och ett produktionsmål,
- samma AppDaemon-implementation ska användas för båda målen,
- utöver instansnamnet ska endast `target_table` skilja konfigurationerna,
- `hydromet.rain_logger_test_events` ska vara en strukturell spegel av `hydromet.event_observations`,
- båda målen använder samma verkliga Nimbus-serie och aktiva mätuppställning,
- `event_id` införs så att flera verkliga tips samma sekund kan lagras utan fabricerade millisekunder,
- idempotens hanteras transaktionellt i `hydromet.event_ingest_keys` i stället för med ett ogiltigt unikt hypertable-index,
- återhämtad mängd lagras som `rain_recovery` med `time_distribution_uncertain`,
- `hydromet-docs` är enda repo som ändras i detta arbete,
- AppDaemon- och HA-filer tas fram som installationsunderlag och läggs in manuellt av användaren,
- `hydromet-core` berörs inte.

## 0.5 — 2026-07-17

Dokumenterat och korrigerat den fysiska ingångskedjan för Nimbus, KISTERS TB4 och Waveshare ESP32-S3-POE-ETH-8DI-8DO.

Tillagt:

```text
docs/hardware/waveshare-esp32-s3-poe-eth-8di-8do.md
docs/installations/sannesholma-nimbus.md
docs/runbooks/nimbus-di1-verification.md
```

Uppdaterat:

```text
docs/index.md
docs/architecture/overview.md
docs/architecture/level-1-logger-design.md
docs/architecture/mqtt-message-contract.md
docs/hardware/index.md
docs/hardware/waveshare-esp32-s3-eth-8di-8ro.md
docs/modules/rain-observatory.md
docs/sources.md
docs/glossary.md
mkdocs.yml
```

Huvudkorrigeringar och beslut:

- den exakta Nimbus-modellen är `Waveshare ESP32-S3-POE-ETH-8DI-8DO`, inte en 8DI-8RO-modell,
- den kanoniska modellidentiteten är `waveshare_esp32_s3_poe_eth_8di_8do`,
- KISTERS TB4:s potentialfria kontakt ska kopplas mellan `DI1` och `DGND`,
- `DICOM/COM` används inte som retur för den passiva TB4-kontakten,
- extern ingångsmatning behövs inte för TB4 eftersom Waveshare-kortet har isolerad terminalmatning,
- `DI1` är internt bunden till `GPIO4`,
- GPIO4:s målkonfiguration är `input + pullup + inverted`,
- pull-up ligger på ESP32-sidan, matar inte TB4 och ersätter inte `DGND`,
- en fri ledning som berörs med finger är inte ett giltigt funktionstest,
- en fysisk digital Nivå 1-ingång måste ha dokumenterad fältretur, polaritet och definierad vilonivå,
- aktiv driftkonfiguration och referensimplementation ska hållas isär och versionsspåras.

Verifierad konfigurationsuppdelning:

```text
Aktiv driftkonfiguration:
MikaelHoogen/home-assistant/esphome/regnlogger-nimbus.yaml

Referensimplementation:
MikaelHoogen/hydromet-core/deployments/sannesholma/nimbus/esphome.yaml
```

Kvarstående operativ avvikelse vid dokumentationstillfället:

```text
Dokumenterad målkonfiguration: GPIO4 input + pullup + inverted
Aktiv granskad konfiguration:  GPIO4 input + inverted
```

Dokumentationspaketet ändrar inte den aktiva Home Assistant-/ESPHome-filen. Pull-up ska införas och verifieras i en separat firmwareändring.

## 0.4 — 2026-06-24

Dokumenterat beslutet att skilja tekniska loggertest från analys- och beräkningstest.

Tillagt:

```text
docs/adr/adr-0009-separate-logger-test-from-analysis-test.md
```

Uppdaterat:

```text
docs/decisions.md
mkdocs.yml
```

Huvudbeslut:

- ESP/logger får bete sig som produktion även under teknisk verifiering,
- tekniska loggertest får skrivas till separat testtabell,
- teknisk testtabell ska inte användas för IDF, återkomsttid eller produktionsstatistik,
- analys- och beräkningstest ska gå genom samma observationsmodell som produktion men märkas som testdata.

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
