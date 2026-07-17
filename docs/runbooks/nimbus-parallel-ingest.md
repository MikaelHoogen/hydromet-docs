# Nimbus parallell ingest: installation och verifiering

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
- finns inte

hydromet.observation_series
- innehåller en gammal testserie rain.test.tb4_test

hydromet.measurement_setups
- innehåller en gammal testlogger-setup
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
- skapar `hydromet.event_ingest_keys`,
- tar bort den tidigare planerade ogiltiga unika counter-indexmodellen.

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

Följande installationsfiler har tagits fram separat från detta repo:

```text
appdaemon/nimbus_rain_ingest.py
config/nimbus_ingest_apps.yaml
config/appdaemon_mqtt.yaml.snippet
```

Den gemensamma Python-klassen ska installeras i AppDaemons Hydromet-appkatalog.

De två AppDaemon-blocken ska vara identiska förutom:

```text
target_table
```

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

## 7. Initialt testläge

Installera båda AppDaemon-definitionerna, men börja med:

```text
nimbus_ingest_test        aktiverad
nimbus_ingest_production  avaktiverad
```

Den tidigare direkta Nimbus-instansen av `RainTipIngestHydromet` får inte köras samtidigt.

Vänta tills retained state har behandlats och testmålets baseline har satts.

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
checkpoint återläses
exakt en ny rain_tip-rad skapas
```

## 10. Recovery-test

Recovery-testet verifierar mängdåterhämtning när live-events missas.

1. Stoppa eller avaktivera testinstansen, men låt Nimbus fortsätta vara online.
2. Gör ett känt antal vippningar.
3. Starta eller aktivera testinstansen igen.
4. Låt retained state behandlas.

Förväntat:

```text
en rain_recovery-rad
value = saknade tips × 0.2 mm
quality_flag = time_distribution_uncertain
metadata.recovered_tips = känt antal
inga påhittade individuella tip-tider
```

Radera inte testmålets checkpoint före detta test.

## 11. Växling till produktion

Växla i denna ordning:

```text
1. avaktivera nimbus_ingest_test
2. bekräfta att testinstansen har stannat
3. aktivera nimbus_ingest_production
4. vänta tills produktionsmålets retained baseline har satts
```

Tidigare testperiod backfylls inte till produktion.

Gör därefter en kontrollerad fysisk vippning.

Förväntat:

```text
hydromet.event_observations                exakt en ny rain_tip-rad
hydromet.rain_logger_test_events           ingen ny rad
counter                                    Nimbus aktuella pulse_total
value                                      0.2 mm
```

## 12. Växling tillbaka till test

```text
1. avaktivera nimbus_ingest_production
2. bekräfta att produktionsinstansen har stannat
3. aktivera nimbus_ingest_test
```

Testmålets egen checkpoint används. Produktionstabellen ska inte påverkas.

## 13. Felsökning

### Måltabellen saknas

Kör migrations- och verifieringsfilerna i avsnitt 3–4.

### Nimbus-serien saknas

Kör `004_seed_nimbus_series.sql` och verifiera att exakt en aktiv setup finns.

### Tips syns i MQTT men inte i databasen

Kontrollera:

```text
rätt AppDaemon-instans är aktiverad
MQTT namespace och event_name stämmer
Nimbus-identiteterna i payload stämmer
DB-användaren har INSERT-rättighet
hydromet.event_ingest_keys kan skrivas
måltabellen kan skrivas
```

### Båda tabellerna får data

Båda AppDaemon-instansierna är aktiverade. Avaktivera omedelbart det oönskade målet och dokumentera tidsintervallet.

### Counter regression

Stoppa automatisk driftbedömning och jämför:

```text
loggerns pulse_total
checkpoint
boot_count
firmwarepersistens
senaste databasrader
```

Regression får inte döljas eller normaliseras bort.

## 14. Godkännandekriterier

Nimbus parallella ingest är godkänd när:

- tabellpariteten är verifierad,
- tio verkliga tips ger exakt tio rader i testmålet,
- omstart inte skapar dubbletter,
- recovery ger rätt mängd och tidsosäker flagga,
- växling till produktion bara skriver till produktionstabellen,
- växling tillbaka bara skriver till testtabellen,
- den äldre syntetiska testkedjan och `public.*` är opåverkade.
