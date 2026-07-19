# Nimbus test- och produktionsingest

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

Styrande beslut finns i:

- [ADR-0011](../adr/adr-0011-nimbus-parallel-test-production-ingest.md) för gemensam ingestkod, tabellparitet, idempotens och checkpoint,
- [ADR-0012](../adr/adr-0012-one-way-nimbus-cutover-and-reproducible-analysis-tests.md) för envägsväxling och teststrategi efter produktionssättning.

## 2. Två ingestmål under acceptans och produktionssättning

```text
Tekniskt acceptanstest:
regnlogger/sannesholma/nimbus/rain_1/tip + state
→ Nimbus-ingest
→ hydromet.rain_logger_test_events

Produktion:
regnlogger/sannesholma/nimbus/rain_1/tip + state
→ Nimbus-ingest
→ hydromet.event_observations
```

Testet använder verklig mätare, verklig loggeridentitet, verkliga MQTT-topics och samma databaslogik som produktion.

Testmålet är dock ett avgränsat steg före första produktionssättningen. Det är inte ett permanent A/B-reglage för den fysiska `rain_1`-kanalen.

## 3. En kodväg

AppDaemon-implementationen ska bestå av en gemensam klass och två möjliga instanser.

De två konfigurationsblocken ska vara identiska förutom:

```yaml
target_table: hydromet.rain_logger_test_events
```

respektive:

```yaml
target_table: hydromet.event_observations
```

Idempotens och mottagartillstånd separeras internt genom `target_table`. Inga separata filvägar eller andra beteendeskillnader ska behöva konfigureras.

Endast ett mål får vara aktivt åt gången.

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

## 10. Första baseline och envägsväxling

Test och produktion har var sitt databaslagrat mottagartillstånd.

När ett mål aktiveras för första gången:

```text
retained state pulse_total
→ baseline för just (target_table, series_id)
```

Därmed kopieras inte tidigare testperiod automatiskt in i produktion när produktionsinstansen aktiveras första gången.

Den första växlingen är därför säker:

```text
tekniskt acceptanstest
→ stoppa testinstansen
→ starta produktionsinstansen
→ sätt första produktionsbaseline
→ verifiera produktionsvippning
```

Efter detta ska den verkliga Nimbus-kanalen stanna i produktion.

## 11. Varför återkommande växling inte är säker

Test och produktion har separata checkpoints men följer samma globala monotona `pulse_total`.

Det som är isolerat är:

```text
eventtabell
idempotensnycklar
mottagarcheckpoint
```

Det som inte är isolerat är:

```text
MQTT-strömmen
kanalen
loggerns pulse_total
```

Exempel:

```text
produktionens checkpoint = 120
produktionen stoppas
fem manuella testvippningar höjer pulse_total till 125
produktionen startas igen
```

Produktionens gamla checkpoint kan då inte veta att pulserna var test och skulle kunna skapa en `rain_recovery` på 1,0 mm.

Samma problem finns åt andra hållet med verkligt produktionsregn som inträffar medan testinstansen är avstängd.

Därför gäller:

```text
ingen återkommande växling tillbaka till test efter första produktionsbaseline
```

## 12. Test av intensitets- och analysberäkningar

`hydromet.rain_logger_test_events` är en teknisk ingest-testtabell. Den ska inte användas som generell utvecklingsdatabas för:

```text
rullande intensiteter
fasta fönster
regnhändelser
IDF
återkomsttid
kvalitetsalgoritmer
```

Sådana tester ska använda reproducerbara testserier med egna identiteter, kontrollerade tidsstämplar, counters, luckor och förväntade resultat.

Nya analysversioner får skuggköras read-only mot produktionsobservationer, men resultatet ska vara versionerat eller isolerat från aktiv produktion.

## 13. Krav för framtida fysisk testkanal

En permanent fysisk end-to-end-testväg efter produktionssättning måste minst ha:

```text
separat channel_id
separat räknare
separat MQTT-topic
separat series_key
```

En separat topic utan separat räknare är inte tillräcklig.

## 14. Repo- och driftgräns

```text
hydromet-docs
→ SQL, arkitektur, ADR och verifieringsprocedur

home-assistant
→ aktiv AppDaemon-kod, apps.yaml och driftkonfiguration
```

Filer som hör till Home Assistant tas fram som installationsunderlag och läggs in manuellt av användaren.

`hydromet-core` är inte del av denna implementation.

## 15. Migrationsordning

```text
001_core_observations.sql              redan körd
002_event_observation_dedup.sql        korrigerar identitet, idempotens och mottagartillstånd
003_rain_logger_test_events.sql        skapar spegeltabellen
004_seed_nimbus_series.sql             registrerar Nimbus-serien och setup
verify_nimbus_parallel_storage.sql     kontrollerar paritet, ledger, state och register
```

Körordning och acceptanstest finns i [Nimbus test- och produktionsingest](../runbooks/nimbus-parallel-ingest.md).
