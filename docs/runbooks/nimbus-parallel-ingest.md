# Nimbus test- och produktionsingest: installation och verifiering

Status: Operativ runbook

## 1. Syfte

Runbooken verifierar den verkliga kedjan:

```text
KISTERS TB4
→ Nimbus
→ MQTT tip + retained state
→ AppDaemon
→ Hydromet test- eller produktionstabell
```

Den äldre syntetiska `logger_test`-kedjan och `public.*` ligger utanför detta arbete.

Den fysiska testvägen används för ett avgränsat acceptanstest före första produktionssättningen. Efter att produktionsmålets första baseline har satts ska den verkliga `rain_1`-kanalen stanna i produktion enligt [ADR-0012](../adr/adr-0012-one-way-nimbus-cutover-and-reproducible-analysis-tests.md).

## 2. Förutsättningar

Databasläget inventerades 2026-07-17:

```text
hydromet.event_observations
- finns
- TimescaleDB-hypertable
- en tidsdimension
- en chunk
- komprimering avstängd
- två gamla proof-of-concept-rader

hydromet.rain_logger_test_events
- fanns inte före migration

hydromet.observation_series
- innehöll en gammal testserie rain.test.tb4_test

hydromet.measurement_setups
- innehöll en gammal testlogger-setup
```

De två gamla Hydromet-raderna bevaras. Inga `public.*`-tabeller berörs.

Gör databasbackup innan migrationerna körs.

## 3. SQL-filer och ordning

Kör exakt i denna ordning:

```text
1. sql/hydromet/002_event_observation_dedup.sql
2. sql/hydromet/003_rain_logger_test_events.sql
3. sql/hydromet/004_seed_nimbus_series.sql
4. sql/hydromet/verify_nimbus_parallel_storage.sql
```

Kör inte äldre lokala kopior av `002` eller `003` före dessa versioner.

### 3.1 Korrigerad 002

Filen:

- lägger till `event_id`,
- bevarar befintliga rader,
- ersätter primärnyckeln med `(time, event_id)`,
- ersätter counter-indexet med den gemensamma formen `(series_id, event_type, counter)`,
- skapar `hydromet.event_ingest_keys`,
- skapar `hydromet.event_ingest_state`,
- tar bort den tidigare planerade ogiltiga unika counter-indexmodellen.

`event_ingest_state` är mottagarens transaktionella checkpoint per:

```text
(target_table, series_id)
```

### 3.2 Korrigerad 003

Filen:

- stoppar om testtabellen redan finns,
- bygger testtabellen från den korrigerade produktionstabellen,
- återskapar foreign keys, primärnyckel, hypertable och motsvarande index.

### 3.3 Nimbus-register

`004_seed_nimbus_series.sql` registrerar:

```text
series_key = rain.sannesholma.nimbus.rain_1.tb4_0p2
```

och en aktiv mätuppställning för KISTERS TB4 och Nimbus.

Den skriver inga regnobservationer.

## 4. Verifiering efter SQL

Kör:

```text
sql/hydromet/verify_nimbus_parallel_storage.sql
```

Godkänt resultat innebär:

- båda måltabellerna finns,
- båda är hypertables,
- `event_ingest_keys` och `event_ingest_state` finns,
- kolumnjämförelsen ger inga avvikelser,
- båda primärnycklarna är `{time,event_id}`,
- båda tabellerna har motsvarande foreign keys,
- Nimbus-serien och aktiv setup finns,
- dubblettkontrollen ger inga rader.

Avbryt AppDaemon-installationen om tabellpariteten inte är godkänd.

## 5. Home Assistant-/AppDaemon-filer

Aktiv driftimplementation hör hemma i:

```text
MikaelHoogen/home-assistant
```

och läggs in manuellt av användaren.

Den gemensamma Python-klassen ska installeras som:

```text
appdaemon/apps/hydromet/rain_logger_level1_ingest.py
```

Klass:

```text
RainLoggerLevel1Ingest
```

Test- och produktionsblocken ska vara identiska förutom:

```text
target_table
```

Appen ska läsa och uppdatera `hydromet.event_ingest_state`; en separat lokal checkpointfil ska inte vara primär sanning.

Endast ett av blocken får vara aktivt åt gången.

## 6. MQTT-plugin

AppDaemon måste prenumerera på:

```text
regnlogger/sannesholma/nimbus/rain_1/#
```

med:

```text
namespace = mqtt
event_name = MQTT_MESSAGE
```

Skapa inte ett andra MQTT-plugin om motsvarande plugin redan finns.

Verifierad startlogg för version 0.3.0 ska visa bland annat:

```text
version=rain-logger-level1-ingest-0.3.0
subscription=regnlogger/sannesholma/nimbus/rain_1/#
mqtt_connected=True
```

## 7. Initialt testläge

Börja med endast testinstansen aktiv:

```text
nimbus_ingest_test        aktiv
nimbus_ingest_production  inte aktiv
```

Den tidigare direkta Nimbus-instansen av `RainTipIngestHydromet` får inte köras samtidigt.

Vänta tills retained state har behandlats och testmålets databaslagrade baseline har satts.

Förväntad logg:

```text
Retained baseline satt:
target=hydromet.rain_logger_test_events
pulse_total=<aktuellt värde>
boot_count=<aktuellt värde>
```

Verifiera baseline:

```sql
SELECT
    target_table,
    series_id,
    last_seen_pulse_total,
    last_boot_count,
    updated_at
FROM hydromet.event_ingest_state
WHERE target_table = 'hydromet.rain_logger_test_events';
```

Baseline får inte skapa en falsk `rain_tip` eller `rain_recovery`.

## 8. Grundtest med verklig TB4

Anteckna Nimbus aktuella `pulse_total`.

Gör tio långsamma manuella vippningar.

Förväntat:

```text
Nimbus pulse_total                         +10
hydromet.rain_logger_test_events           10 nya rain_tip-rader
counter                                    10 stigande värden
sum(value)                                 2.0 mm
hydromet.event_observations                inga nya Nimbus-rader
dubblettkontroll                           inga rader
event_ingest_state                         uppdaterat till sista counter
```

Varje rad ska ha:

```text
event_type = rain_tip
unit = mm
value = 0.2
series_id = Nimbus-serien
setup_id = aktiv Nimbus-setup
```

## 9. Omstartstest

1. Gör några testvippningar.
2. Starta om AppDaemon.
3. Vänta tills retained state har behandlats.
4. Gör en ny vippning.

Förväntat:

```text
gamla counters skrivs inte om
databasens mottagartillstånd återläses
exakt en ny rain_tip-rad skapas
ingen rain_recovery skapas av omstarten
```

För ett hårdare kraschtest ska testet även omfatta omstart direkt efter en lyckad databasinsert. Eftersom observation, idempotensnyckel och mottagartillstånd bekräftas i samma transaktion ska ingen dubbel recovery skapas.

## 10. Recovery-test före produktionssättning

Recovery-testet verifierar mängdåterhämtning när live-events missas.

1. Stoppa eller ta bort testinstansen ur aktiv appkonfiguration, men låt Nimbus fortsätta vara online.
2. Gör ett känt antal vippningar.
3. Starta testinstansen igen.
4. Låt retained state behandlas.

Förväntat:

```text
en rain_recovery-rad
value = saknade tips × 0.2 mm
quality_flag = time_distribution_uncertain
metadata.recovered_tips = känt antal
inga påhittade individuella tip-tider
event_ingest_state uppdateras till retained pulse_total
```

Ändra eller radera inte testmålets rad i `hydromet.event_ingest_state` före detta test.

Recovery-testet ska vara avslutat och verifierat innan produktionsmålets första baseline sätts.

## 11. Engångsväxling till produktion

Växla i denna ordning:

```text
1. stoppa eller ta bort nimbus_ingest_test ur aktiv appkonfiguration
2. bekräfta i loggen att testinstansen har stannat
3. lägg till eller aktivera nimbus_ingest_production
4. kontrollera att target=hydromet.event_observations
5. vänta tills produktionsmålets retained baseline har satts
```

Första produktionsstarten ska visa:

```text
last_seen=None
```

följt av en separat baseline för:

```text
target=hydromet.event_observations
```

Tidigare testperiod backfylls inte till produktion eftersom produktionsmålet ännu inte hade någon checkpoint.

Kontrollera att en separat produktionsrad har skapats i `hydromet.event_ingest_state`:

```sql
SELECT
    target_table,
    series_id,
    last_seen_pulse_total,
    last_boot_count,
    updated_at,
    metadata
FROM hydromet.event_ingest_state
WHERE target_table = 'hydromet.event_observations'
  AND series_id = '<Nimbus series_id>'::uuid;
```

Gör därefter en kontrollerad fysisk vippning.

Förväntat:

```text
hydromet.event_observations                exakt en ny rain_tip-rad
hydromet.rain_logger_test_events           ingen ny rad
counter                                    Nimbus aktuella pulse_total
value                                      0.2 mm
ingen rain_recovery                        för den normala vippningen
```

## 12. Efter produktionsbaseline

När produktionsmålets första baseline har satts gäller:

```text
Nimbus rain_1 stannar i produktion.
```

Återaktivera inte testinstansen mot samma kanal och samma `pulse_total` som ett normalt testförfarande.

Orsak:

```text
test och produktion har separata checkpoints
men delar samma loggerägda pulse_total
```

En senare återstart av en gammal checkpoint kan därför tolka testvippningar eller produktionsregn som missade pulser och skapa felaktig recovery.

Det finns ingen säker generell "växla tillbaka till test"-procedur för den befintliga fysiska kanalen.

## 13. Test av intensitets- och analysberäkningar

Använd inte `hydromet.rain_logger_test_events` eller manuella Nimbus-vippningar som generell testmiljö för TimescaleDB-analyser.

Utveckling av rullande intensiteter, fasta fönster, händelser, IDF och kvalitetslogik ska använda:

```text
separata testserier
egna series_id
kontrollerade tidsstämplar
kontrollerade counters
kända luckor och recoveries
förväntade resultat
```

Nya beräkningsversioner får skuggköras read-only mot verkliga produktionsobservationer, med versionerade eller isolerade resultat.

## 14. Felsökning

### Måltabellen saknas

Kör migrations- och verifieringsfilerna i avsnitt 3–4.

### Nimbus-serien saknas

Kör `004_seed_nimbus_series.sql` och verifiera att exakt en aktiv setup finns.

### Tips syns i MQTT men inte i databasen

Kontrollera:

```text
rätt AppDaemon-instans är aktiv
MQTT namespace och event_name stämmer
Nimbus-identiteterna i payload stämmer
DB-användaren har INSERT-rättighet
hydromet.event_ingest_keys kan skrivas
hydromet.event_ingest_state kan skrivas
måltabellen kan skrivas
```

### Båda tabellerna får data

Båda AppDaemon-instansierna är aktiva. Stoppa omedelbart det oönskade målet och dokumentera tidsintervallet.

### Produktion skapar recovery efter testväxling

Stoppa vidare växling. Jämför:

```text
produktionens checkpoint
testets checkpoint
loggerns aktuella pulse_total
tidsintervallet då respektive instans var aktiv
verkligt regn kontra manuella testvippningar
```

Radera eller flytta inte checkpointen utan separat analys. En manuell baselineflytt kan samtidigt kasta bort verkligt regn.

### Counter regression

Stoppa automatisk driftbedömning och jämför:

```text
loggerns pulse_total
hydromet.event_ingest_state.last_seen_pulse_total
boot_count
firmwarepersistens
senaste databasrader
```

Regression får inte döljas eller normaliseras bort.

## 15. Godkännandekriterier

Nimbus-ingesten är godkänd för produktion när:

- tabellpariteten är verifierad,
- `event_ingest_keys` och `event_ingest_state` är verifierade,
- tio verkliga tips ger exakt tio rader i testmålet,
- omstart inte skapar dubbletter eller falsk recovery,
- recovery ger rätt mängd och tidsosäker flagga,
- databasens mottagartillstånd följer sista bekräftade counter,
- första växlingen till produktion sätter en ny baseline utan att backfylla testperioden,
- en kontrollerad produktionsvippning bara skrivs till produktionstabellen,
- testinstansen därefter inte används som återkommande A/B-läge,
- den äldre syntetiska testkedjan och `public.*` är opåverkade.
