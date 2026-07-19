# ADR-0011: Nimbus har gemensam test- och produktionsingest

Status: Antagen, växlingssemantiken ersatt av [ADR-0012](adr-0012-one-way-nimbus-cutover-and-reproducible-analysis-tests.md)  
Datum: 2026-07-17  
Korrigerat: 2026-07-19

## Kontext

Nimbus är den verkliga Nivå 1-regnloggern i Sännesholma:

```text
KISTERS TB4
→ Waveshare ESP32-S3-POE-ETH-8DI-8DO
→ MQTT tip + retained state
→ AppDaemon-ingest
→ Hydromet-databas
```

Loggerkedjan behöver kunna verifieras före produktionssättning utan att tekniska tester blandas in i produktionsobservationer.

Detta beslut gäller inte den äldre syntetiska `logger_test`-kedjan eller historiska tabeller under `public.*`. Den äldre kedjan får fortsätta leva separat.

Tidigare dokumentation angav en separat teknisk testtabell, men den implementerade SQL-modellen gjorde testtabellen strukturellt annorlunda än produktionstabellen. Ett sådant test kan visa att någon databasskrivning fungerar, men inte att den verkliga produktionsvägen fungerar.

Dessutom identifierades två tekniska problem i den påbörjade produktionsmodellen:

1. `hydromet.event_observations` använde primärnyckeln `(time, series_id, event_type)`, trots att Nimbus publicerar `epoch_s` med sekundupplösning och kan registrera fler än en giltig puls under samma sekund.
2. ett planerat unikt index på `(series_id, event_type, counter)` saknade hypertablens partitioneringskolumn `time` och är därför inte en giltig unikhetsmodell för en TimescaleDB-hypertable.

## Beslut

Nimbus ska ha två tillgängliga ingestmål under acceptans och produktionssättning:

```text
Test:
verklig Nimbus MQTT
→ Nimbus AppDaemon-ingest
→ hydromet.rain_logger_test_events

Produktion:
verklig Nimbus MQTT
→ Nimbus AppDaemon-ingest
→ hydromet.event_observations
```

Testmålet används för initial teknisk acceptans. När produktionsmålets första baseline har satts ska den verkliga Nimbus-kanalen stanna i produktion enligt ADR-0012.

### En gemensam implementation

Det ska finnas en gemensam AppDaemon-klass som kan instansieras för test eller produktion.

De två instanserna ska använda samma:

```text
MQTT-topics
identitetskontroll
pulse_total-logik
state reconciliation
checkpointprincip
gap-detektering
recoverylogik
tidshantering
seriemappning
mätuppställningsmappning
SQL-insert
kvalitetsflaggor
```

Utöver AppDaemon-instansens namn är den enda avsiktliga konfigurationsskillnaden:

```text
target_table
```

Måltabellen används internt för att separera idempotens och mottagartillstånd mellan test och produktion.

### Tabellparitet

`hydromet.rain_logger_test_events` ska spegla `hydromet.event_observations` i:

```text
kolumnordning
kolumnnamn
datatyper
null-regler
defaults
CHECK-constraints
foreign-key-semantik
primärnyckelns form
hypertable-status
indexens form
```

Constraint- och indexnamn får skilja eftersom PostgreSQL-namn är globala inom schemat.

Test och produktion ska använda samma verkliga Nimbus-serie och samma aktiva mätuppställning. Testisolering sker genom måltabellen, inte genom att Nimbus felaktigt registreras som en syntetisk testkälla.

### Händelseidentitet

Båda händelsetabellerna ska ha:

```text
event_id uuid
PRIMARY KEY (time, event_id)
```

`time` behålls i primärnyckeln eftersom TimescaleDB kräver partitioneringskolumnen i unika index. `event_id` gör det möjligt att lagra flera verkliga händelser med samma hela sekund utan att fabricera millisekunder.

### Idempotens och dubblettskydd

Exakt idempotens ska inte byggas med ett unikt counter-index direkt på hypertabellen.

I stället används en vanlig PostgreSQL-tabell:

```text
hydromet.event_ingest_keys
```

Nyckeln består av:

```text
target_table
source_event_key
```

`source_event_key` ska härledas från stabil loggeridentitet och stabil counter-/intervallsemantik. Föränderliga diagnostikfält som aktuell uptime får inte vara nödvändiga för att samma källhändelse ska kännas igen efter omstart.

Ledger- och observationsinsert ska ske i samma databastransaktion. Test och produktion får därmed separata idempotensområden trots att de läser samma loggeridentitet.

### Transaktionellt mottagartillstånd

Mottagarens senaste bekräftade `pulse_total` ska lagras i:

```text
hydromet.event_ingest_state
```

Nyckeln är:

```text
(target_table, series_id)
```

Baseline, normal tip, recovery och mottagartillstånd ska uppdateras i samma databastransaktion när en observation skrivs. En separat filcheckpoint får inte vara den primära sanningen, eftersom en krasch efter databascommit men före filskrivning annars kan orsaka dubbel recovery.

När AppDaemon startar ska den läsa senaste målspecifika mottagartillstånd från databasen.

### Normal puls och återhämtning

En normal live-puls lagras som:

```text
event_type = rain_tip
value = 0.2
unit = mm
counter = pulse_total
```

Saknad mängd som upptäcks genom räknarhopp eller retained state lagras som en sammanlagd observation:

```text
event_type = rain_recovery
value = recovered_tips × 0.2 mm
counter = sista återvunna räknarvärdet
quality_flag = time_distribution_uncertain
```

Återhämtning får inte omvandlas till påhittade individuella tip-tider.

### Första produktionssättning

Under initial teknisk acceptans gäller:

```text
testinstans aktiv
produktionsinstans inte aktiv
```

Vid produktionssättning gäller:

```text
1. stoppa testinstansen
2. bekräfta att den har stannat
3. starta produktionsinstansen
4. vänta på första retained baseline
5. verifiera en produktionsvippning
```

När produktionsmålet aktiveras första gången används dess retained `pulse_total` som målets databaslagrade baseline. Testperiodens tidigare pulser backfylls därför inte till produktion.

### Ingen återkommande växling

Test och produktion har separata checkpoints men följer samma globala `pulse_total`. Måltabellen isolerar därför inte mätströmmen.

Efter att produktionsmålets första baseline har satts får den verkliga `rain_1`-kanalen inte växlas tillbaka till testinstansen i normal drift. En senare återstart av en gammal checkpoint skulle tolka räknarökningen som missad nederbörd och kunna skapa felaktig recovery.

Återkommande fysisk testning kräver en separat kanal och separat räknare enligt ADR-0012.

## Repoavgränsning

```text
MikaelHoogen/hydromet-docs
= metod, arkitektur, datamodell, SQL och långsiktig dokumentation

MikaelHoogen/home-assistant
= aktiv implementation och driftmiljö
```

AppDaemon- och HA-filer skrivs inte automatiskt från detta arbete till Home Assistant-repot. De tas fram som installationsunderlag och läggs in där av användaren.

`MikaelHoogen/hydromet-core` berörs inte av detta beslut. Nimbus/AppDaemon/TimescaleDB-driften är intern observatorieimplementation och hör inte till RainLens-kärnan i detta skede.

## Konsekvenser

### Positiva

- testet verifierar samma lagringsmodell som produktion,
- test- och produktionskod kan inte glida isär utan att konfigurationspariteten bryts,
- flera tips under samma sekund kan lagras korrekt,
- dubbletter kan stoppas transaktionellt,
- mottagartillstånd och observationscommit kan inte glida isär på grund av en separat filcheckpoint,
- återhämtad mängd kan lagras utan falsk tidsprecision,
- första produktionssättningen kan göras utan att tidigare testvippningar backfylls,
- den äldre syntetiska testkedjan påverkas inte.

### Begränsningar

- Nivå 1 har fortfarande ingen lokal eventjournal och inget backend-ack/replay,
- exakt tidsfördelning kan gå förlorad under avbrott,
- endast avsett mål får vara aktivt,
- testmålet är ett acceptansmål och inte ett permanent A/B-reglage efter produktionssättning,
- SQL-migrationerna måste verifieras mot den faktiska databasen före AppDaemon-start.

## Berörda migrationsfiler

```text
sql/hydromet/002_event_observation_dedup.sql
sql/hydromet/003_rain_logger_test_events.sql
sql/hydromet/004_seed_nimbus_series.sql
sql/hydromet/verify_nimbus_parallel_storage.sql
```
