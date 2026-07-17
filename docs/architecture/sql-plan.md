# SQL-plan

Status: Aktiv byggordning för Hydromet-databasen

Senast uppdaterad: 2026-07-17

Syfte: Låsa byggordningen för databas, ingest, verifiering och senare analyslager utan att blanda ihop historisk prototyp, verkliga Nimbus-test och produktionsobservationer.

## 1. Grundprincip

Systemet ska byggas nerifrån och upp, men inte som en ren regndatabas.

```text
hydromet core
→ generella observationsserier och råobservationer
→ systemhälsa
→ verklig Nimbus test-/produktionsingest
→ regnmodul
→ normaliserade regnserier
→ varaktigheter
→ IDF-trösklar
→ klassning
→ händelser
→ rapporter och presentation
```

Designregler:

```text
Ingen avancerad analys ska byggas innan rådata, serieregister och mätkedjans hälsa är stabila.
```

```text
Grunddatabasen ska kunna bära fler sensortyper än regn.
```

```text
Tekniska loggertest och analys-/beräkningstest ska hållas isär.
```

```text
Den äldre syntetiska logger_test-kedjan och verkliga Nimbus parallella ingest är två olika system.
```

## 2. PostgreSQL och TimescaleDB

Databasen bygger på PostgreSQL med TimescaleDB för tabeller som växer som tidsserier.

PostgreSQL används för:

```text
relationsmodell
metadata
constraints
foreign keys
jsonb
vanlig SQL
vyer
idempotensledger
```

TimescaleDB används för:

```text
hypertables för tidsbaserade observationstabeller
effektivare frågor över tid
framtida time_bucket-beräkningar
framtida continuous aggregates
framtida komprimering av äldre tidschunks
```

Aktuella och planerade hypertables:

```text
hydromet.point_observations        → time
hydromet.interval_observations     → interval_start
hydromet.event_observations        → time
hydromet.rain_logger_test_events   → time
hydromet.system_health             → time
```

Vanliga PostgreSQL-tabeller används när exakt unikhet över en icke-tidsbaserad källnyckel behövs. Nimbus använder:

```text
hydromet.event_ingest_keys
```

Designregel:

```text
Använd TimescaleDB enkelt i början: hypertables först, avancerade funktioner när verkliga frågemönster finns.
```

## 3. MVP 0 — historisk prototyp

Historisk implementation och äldre testdata finns under:

```text
public.*
```

Den äldre syntetiska `logger_test`-kedjan får leva vidare separat. Detta arbete ändrar eller migrerar inte automatiskt dess tabeller.

Tolkning:

```text
public.*   = historisk prototyp och äldre testkedja
hydromet.* = långsiktig observationsmodell
```

Migrering från historiska tabeller ska vara explicit och icke-destruktiv.

## 4. Faktiskt Hydromet-läge 2026-07-17

Inventeringen visade:

```text
hydromet.event_observations
- finns
- TimescaleDB-hypertable
- en dimension
- en chunk
- komprimering avstängd
- två gamla proof-of-concept-rader

hydromet.observation_series
- en gammal testserie: rain.test.tb4_test

hydromet.measurement_setups
- en gammal testlogger-setup

hydromet.rain_logger_test_events
- finns inte
```

Hydromet är därmed en påbörjad kärnmodell, inte etablerad Nimbus-produktion. De två gamla raderna bevaras, men de styr inte den nya Nimbus-arkitekturen.

## 5. Aktiv migrationsordning

### 001 — Hydromet core

```text
sql/hydromet/001_core_observations.sql
```

Skapar:

```text
hydromet.observation_series
hydromet.measurement_setups
hydromet.point_observations
hydromet.interval_observations
hydromet.event_observations
hydromet.system_health
hydromet.system_alerts
```

Status i faktisk databas: körd.

### 002 — Händelseidentitet och idempotens

```text
sql/hydromet/002_event_observation_dedup.sql
```

Den korrigerade migrationen:

- lägger till `event_id uuid`,
- bevarar befintliga rader,
- ändrar primärnyckeln till `(time, event_id)`,
- tillåter flera verkliga events under samma sekund,
- skapar `hydromet.event_ingest_keys`,
- använder inte ett ogiltigt unikt hypertable-index utan `time`.

Bakgrund:

Nimbus publicerar `epoch_s` med sekundupplösning. Primärnyckeln `(time, series_id, event_type)` kan därför kollidera för två giltiga tips samma sekund.

TimescaleDB kräver dessutom att partitioneringskolumnen ingår i varje unikt index på en hypertable. Exakt idempotens på loggerns källnyckel hanteras därför i en vanlig PostgreSQL-ledger.

### 003 — Permanent spegeltabell för verkliga Nimbus-test

```text
sql/hydromet/003_rain_logger_test_events.sql
```

Skapar:

```text
hydromet.rain_logger_test_events
```

Tabellen ska spegla den korrigerade `hydromet.event_observations` i:

```text
kolumner
datatyper
null-regler
defaults
CHECK-constraints
foreign-key-semantik
primärnyckel
hypertable-status
indexform
```

Den är ett permanent tekniskt mål för verkliga Nimbus MQTT-data. Den är inte en del av den äldre syntetiska `logger_test`-kedjan.

Tabellen får inte användas för:

```text
IDF
återkomsttid
varaktigheter
händelsestatistik
produktionssummeringar
lokal extremvärdesstatistik
```

### 004 — Nimbus observationsserie och mätuppställning

```text
sql/hydromet/004_seed_nimbus_series.sql
```

Registrerar:

```text
series_key = rain.sannesholma.nimbus.rain_1.tb4_0p2
```

samt en aktiv mätuppställning för:

```text
KISTERS TB4
0.2 mm per tip
DI1–DGND
GPIO4
Waveshare ESP32-S3-POE-ETH-8DI-8DO
PoE/Ethernet
ESP-IDF
firmware rainlens-level1-0.1.1
```

Både test- och produktionsmålet använder samma verkliga serie och setup. Isolering sker genom måltabellen.

### Verifiering

```text
sql/hydromet/verify_nimbus_parallel_storage.sql
```

Kontrollerar:

```text
tabellernas existens
hypertable-status
kolumnparitet
primärnyckelparitet
foreign-key-paritet
indexform
Nimbus serie/setup
dubblettgrupper
senaste Nimbus-rader i båda mål
```

AppDaemon-installationen ska inte startas innan verifieringen är godkänd.

## 6. Nimbus AppDaemon-ingest

Den aktiva implementationen hör till Home Assistant-repot och läggs in manuellt av användaren.

Arkitekturkrav:

```text
en gemensam Python-klass
två AppDaemon-instansieringar
samma topics och identiteter
samma pulse_total- och state-logik
samma recovery
samma SQL-insert
enda avsiktliga konfigurationsskillnaden: target_table
```

Mål:

```text
test       → hydromet.rain_logger_test_events
produktion → hydromet.event_observations
```

Checkpoint och idempotensområde ska vara separata per måltabell.

Styrande dokument:

- [Nimbus parallella ingest](nimbus-parallel-ingest.md)
- [ADR-0011](../adr/adr-0011-nimbus-parallel-test-production-ingest.md)
- [Nimbus parallell ingest: installation och verifiering](../runbooks/nimbus-parallel-ingest.md)

## 7. Händelsemappning

Normal tipping bucket-puls:

```text
MQTT tip.epoch_s                    → event_observations.time
mottagartid                         → received_at
Nimbus series                       → series_id
aktiv Nimbus setup                  → setup_id
event                               → event_type = rain_tip
mm                                  → value
unit                                → mm
pulse_total                         → counter
payload                             → raw_payload
raw_pulse_total                     → metadata.raw_pulse_total
ignored_pulse_total                 → metadata.ignored_pulse_total
interval_ms                         → metadata.interval_ms
uptime_ms                           → metadata.uptime_ms
time_valid / epoch_s                → metadata
```

Återhämtad mängd:

```text
event_type                          → rain_recovery
recovered_tips × mm_per_tip         → value
sista återvunna counter             → counter
quality_flag                        → time_distribution_uncertain
counterintervall och orsak          → metadata
mottagartid                         → time
```

Exakta individuella tip-tider får inte konstrueras i efterhand.

## 8. Regnmodul ovanpå core

Regnspecifika vyer och tabeller byggs efter att Nimbus råingest och mätkedjans hälsa är stabila.

Ett migrationsnummer för regnmodulen är ännu inte låst. Det tidigare konceptnamnet `002_rain_module.sql` är inaktuellt eftersom migrationsnummer `002–004` nu används av den faktiska kärn- och Nimbus-ingesten.

Planerade objekt:

```text
normaliserade minut-/intervallserier
rain_duration_values
idf_thresholds
rain_return_period_results
rain_events
rain_event_duration_profile
```

## 9. Senare steg

```text
normaliserade regnserier
rullande och fasta varaktigheter
IDF-trösklar
återkomstklassning
regnhändelser
Home Assistant-publicering
Grafana
lokal IDF på lång sikt
```

Det som inte ska byggas före stabil råingest:

```text
full händelselogik
lokal IDF
POT-analys
årsmaxstatistik
klimatprediktor-IDF
nationell plattform
skyfallskarteringsjämförelse
avancerad Grafana-dashboard
avancerad flödes-/nivåanalys
vindanalys
markfuktsanalys
vattenkvalitetsanalys
```

## 10. Repoavgränsning

```text
MikaelHoogen/hydromet-docs
= SQL, metod, arkitektur, datamodell och verifiering

MikaelHoogen/home-assistant
= aktiv AppDaemon-implementation och driftmiljö
```

Filer som ska in i Home Assistant-repot läggs in manuellt av användaren.

`MikaelHoogen/hydromet-core` är inte del av den interna Nimbus/AppDaemon/TimescaleDB-implementationen i detta skede.
