# SQL-plan

Status: Planerad / konceptuell

Syfte: Låsa byggordningen för databas, vyer, AppDaemon-ingest och Home Assistant-publicering innan faktisk SQL skrivs.

## 1. Grundprincip

Systemet ska byggas nerifrån och upp, men inte som en ren regndatabas.

```text
hydromet core
→ generella observationsserier och råobservationer
→ systemhälsa
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

## 2. MVP 0 — Befintlig prototyp

Nuläge i Home Assistant-miljön:

```text
public.rain_tip_events
```

Den befintliga tabellen är prototypdata/MVP 0 och ska inte raderas i första steget.

Tolkning:

```text
public.rain_tip_events = historisk prototypdata
hydromet.*             = långsiktig struktur
```

Migrering ska ske explicit och icke-destruktivt.

## 3. MVP 1 — Hydromet core

Föreslagen första SQL-fil:

```text
sql/hydromet/001_core_observations.sql
```

Tabeller:

```text
hydromet.observation_series
hydromet.measurement_setups
hydromet.point_observations
hydromet.interval_observations
hydromet.event_observations
hydromet.system_health
hydromet.system_alerts
```

## 4. MVP 1b — Regnmodul ovanpå core

Föreslagen andra SQL-fil:

```text
sql/hydromet/002_rain_module.sql
```

Innehåll:

```text
regnspecifika vyer eller tabeller
migrering från public.rain_tip_events
seed-data för regnserier
```

Regnspecifika objekt:

```text
hydromet.rain_tip_events
hydromet.rain_interval_observations
hydromet.rain_duration_values
hydromet.idf_thresholds
hydromet.rain_return_period_results
hydromet.rain_events
```

## 5. Migration från `public.rain_tip_events`

Fältmappning:

```text
public.rain_tip_events.time          → hydromet.event_observations.time
received_at                          → received_at
sensor_id/source/topic               → används för att hitta series_id
pulse_total                          → counter
mm                                   → value
unit                                 → mm
event                                → event_type = rain_tip
payload                              → raw_payload
payload.raw_pulse_total              → metadata/raw_pulse_total
payload.ignored_pulse_total          → metadata/ignored_pulse_total
payload.interval_ms                  → metadata/interval_ms
payload.gpio                         → metadata/gpio
time_valid / epoch_s                 → metadata/time_valid och metadata/epoch_s
```

Viktig regel:

```text
Mappa inte bara på topic.
Använd sensor_id eftersom flera testserier kan dela topic.
```

## 6. Senare steg

```text
normaliserade regnserier
rullande varaktigheter
IDF-trösklar
återkomstklassning
regnhändelser
Home Assistant-publicering
Grafana
lokal IDF på lång sikt
```

## 7. Vad som inte ska byggas först

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

Dessa ska möjliggöras av kärnmodellen men inte störa första byggsteget.
