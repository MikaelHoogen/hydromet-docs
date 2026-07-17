# Nimbus parallella test- och produktionsingest

Status: Kanonisk arkitektur för intern Nimbus-ingest

## 1. Omfattning

Detta dokument gäller endast den verkliga Nimbus-kedjan i Sännesholma:

```text
KISTERS TB4
→ Nimbus
→ MQTT tip + retained state
→ AppDaemon
→ Hydromet-databas
```

Det gäller inte den äldre syntetiska `logger_test`-kedjan eller dess historiska data under `public.*`.

Det styrande beslutet finns i [ADR-0011](../adr/adr-0011-nimbus-parallel-test-production-ingest.md).

## 2. Två permanenta mål

```text
Tekniskt test:
regnlogger/sannesholma/nimbus/rain_1/tip + state
→ Nimbus-ingest
→ hydromet.rain_logger_test_events

Produktion:
regnlogger/sannesholma/nimbus/rain_1/tip + state
→ Nimbus-ingest
→ hydromet.event_observations
```

Testet använder verklig mätare, verklig loggeridentitet, verkliga MQTT-topics och samma databaslogik som produktion.

## 3. En kodväg

AppDaemon-implementationen ska bestå av en gemensam klass och två instanser.

De två konfigurationsblocken ska vara identiska förutom:

```yaml
target_table: hydromet.rain_logger_test_events
```

respektive:

```yaml
target_table: hydromet.event_observations
```

Idempotens och mottagartillstånd separeras internt genom `target_table`. Inga separata filvägar eller andra beteendeskillnader ska behöva konfigureras.

## 4. Gemensam serie och mätuppställning

Båda målen använder:

```text
series_key = rain.sannesholma.nimbus.rain_1.tb4_0p2
```

Serien beskriver den verkliga fysiska Nimbus-observationen och ska ha:

```text
observed_property = precipitation_tip
source_type = mqtt_logger
resolution_type = event
is_primary = true
is_test = false
```

Teknisk testisolering sker i tabellvalet. Nimbus-serien ska inte märkas som syntetisk testserie.

Mätuppställningen ska beskriva:

```text
KISTERS TB4
0.2 mm per tip
DI1–DGND
GPIO4
input + pull-up + inverted
Waveshare ESP32-S3-POE-ETH-8DI-8DO
PoE/Ethernet
ESP-IDF
firmwareversion
```

## 5. Tabellparitet

Testtabellen ska byggas från den korrigerade produktionstabellen och spegla:

```text
time
received_at
series_id
setup_id
event_type
value
unit
counter
quality_flag
raw_payload
metadata
event_id
```

Båda är TimescaleDB-hypertables på `time` och använder:

```text
PRIMARY KEY (time, event_id)
```

Separata namn på index och constraints är tillåtna, men deras form och semantik ska motsvara varandra.

## 6. Varför event_id behövs

Nimbus publicerar `epoch_s` med sekundupplösning. En giltig Nivå 1-puls kan följa mindre än en sekund efter föregående puls.

Primärnyckeln:

```text
(time, series_id, event_type)
```

kan därför kollidera för två giltiga `rain_tip` under samma sekund.

`event_id` gör händelserna unika utan att hitta på millisekunder som loggern inte har observerat.

## 7. Idempotens

Loggerns `pulse_total` är den bästa tillgängliga källan för ackumulerad Nivå 1-data, men ett exakt unikt counter-index kan inte läggas direkt på en hypertable utan att även innehålla `time`.

Därför används:

```text
hydromet.event_ingest_keys
```

med primärnyckeln:

```text
(target_table, source_event_key)
```

`source_event_key` ska vara stabil över omstarter. Den ska bygga på loggeridentitet och counter-/intervallsemantik, inte på föränderliga diagnostikvärden som aktuell uptime.

Ledger- och observationsinsert sker i samma transaktion. Om observationens insert misslyckas ska inte heller ledgernyckeln bekräftas.

## 8. Transaktionellt mottagartillstånd

Senaste bekräftade `pulse_total` för varje mål lagras i:

```text
hydromet.event_ingest_state
```

med nyckeln:

```text
(target_table, series_id)
```

Tabellen innehåller minst:

```text
last_seen_pulse_total
last_boot_count
updated_at
metadata
```

När en normal tip eller recovery lagras ska följande ske i samma transaktion:

```text
idempotensnyckel
→ observation
→ uppdaterat mottagartillstånd
```

En separat filcheckpoint är inte primär sanning. Det undviker läget där databastransaktionen lyckas men en efterföljande filskrivning misslyckas eller avbryts, vilket annars kan orsaka dubbel recovery efter omstart.

## 9. Tip, gap och recovery

Normal tip:

```text
event_type = rain_tip
value = 0.2 mm
counter = pulse_total
```

Om ett live-event visar ett räknarhopp lagras först den saknade mängden som `rain_recovery`, därefter den mottagna normala pulsen.

Om retained state visar ett högre `pulse_total` än databasens mottagartillstånd lagras:

```text
event_type = rain_recovery
value = recovered_tips × 0.2 mm
quality_flag = time_distribution_uncertain
```

Recovery-tiden är mottagartid. Individuella tip-tider konstrueras inte.

## 10. Baseline vid växling

Test och produktion har var sitt databaslagrat mottagartillstånd.

När ett mål aktiveras för första gången:

```text
retained state pulse_total
→ baseline för just (target_table, series_id)
```

Därmed kopieras inte tidigare testperiod automatiskt in i produktion när produktionsinstansen aktiveras.

## 11. Repo- och driftgräns

```text
hydromet-docs
→ SQL, arkitektur, ADR och verifieringsprocedur

home-assistant
→ aktiv AppDaemon-kod, apps.yaml och driftkonfiguration
```

Filer som hör till Home Assistant tas fram som installationsunderlag och läggs in manuellt av användaren.

`hydromet-core` är inte del av denna implementation.

## 12. Migrationsordning

```text
001_core_observations.sql              redan körd
002_event_observation_dedup.sql        korrigerar identitet, idempotens och mottagartillstånd
003_rain_logger_test_events.sql        skapar spegeltabellen
004_seed_nimbus_series.sql             registrerar Nimbus-serien och setup
verify_nimbus_parallel_storage.sql     kontrollerar paritet, ledger, state och register
```

Körordning och acceptanstest finns i [Nimbus parallell ingest](../runbooks/nimbus-parallel-ingest.md).
