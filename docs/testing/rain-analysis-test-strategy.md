# Teststrategi för regnanalys och TimescaleDB-beräkningar

Status: Kanonisk teststrategi  
Beslut: [ADR-0009](../adr/adr-0009-separate-logger-test-from-analysis-test.md) och [ADR-0012](../adr/adr-0012-one-way-nimbus-cutover-and-reproducible-analysis-tests.md)

## 1. Syfte

Detta dokument beskriver hur Hydromet ska testa:

```text
rullande regnvolymer och intensiteter
fasta klockfönster
regnhändelser
varaktighetsprofiler
IDF- och återkomstklassning
kvalitetslogik
recovery-hantering
```

Teststrategin ska ge reproducerbara resultat utan att den fysiska Nimbus-kanalen eller produktionsserien förorenas av manuella testvippningar.

## 2. Tre separata testnivåer

### 2.1 Ingest-acceptans

Syfte:

```text
verifiera fysisk TB4
verifiera Nimbus pulsräkning
verifiera MQTT state och tip
verifiera AppDaemon
verifiera idempotens, recovery och checkpoint
verifiera databasinsert
```

Kedja:

```text
verklig TB4
→ verklig Nimbus rain_1
→ hydromet.rain_logger_test_events
```

Detta är ett avgränsat acceptanstest före första produktionssättningen.

Efter produktionsmålets första baseline ska den fysiska `rain_1`-kanalen inte användas som återkommande testgenerator.

### 2.2 Analys- och beräkningstest

Syfte:

```text
verifiera algoritmer med kända indata och kända förväntade resultat
```

Kedja:

```text
reproducerbara testfixtures
→ samma observationsmodell som produktion
→ samma analyskod som produktion
→ isolerade testresultat
```

Testserier ska ha:

```text
eget series_id
tydlig is_test-markering
kontrollerade tidsstämplar
kontrollerade counters
kontrollerad mm per tip
kontrollerade luckor och recoveries
förväntade resultat
```

### 2.3 Skuggtest på verklig data

Syfte:

```text
jämföra ny kandidatversion mot aktiv analys på realistisk produktionsdata
```

Kedja:

```text
hydromet.event_observations, read-only
→ aktiv analysversion
→ kandidatversion
→ jämförelse
```

Råa produktionsobservationer får aldrig ändras av skuggtestet.

Kandidatresultat ska vara versionerade eller lagras separat tills de har verifierats.

## 3. Testdata är en del av specifikationen

Varje testfixture ska dokumentera:

```text
fixture_id
syfte
indata
förväntat resultat
vilken regel som verifieras
kända kvalitetsflaggor
```

Exempel på fixturemetadata:

```yaml
fixture_id: rolling_15min_basic_001
series_key: rain.test.analytics.tb4_0p2.basic
mm_per_tip: 0.2
expected:
  total_15min_mm: 1.0
  intensity_15min_mm_h: 4.0
```

Fixturedata ska vara deterministisk. Samma test ska ge samma resultat oavsett när och var det körs.

## 4. Minsta testkatalog för intensitetsberäkningar

### 4.1 Grundläggande rullande fönster

```text
5 tips under 5 minuter
→ 1,0 mm
→ 12,0 mm/h för 5-minutersfönstret
```

```text
5 tips under 15 minuter
→ 1,0 mm
→ 4,0 mm/h för 15-minutersfönstret
```

```text
5 tips under 60 minuter
→ 1,0 mm
→ 1,0 mm/h för 60-minutersfönstret
```

### 4.2 Fönstergränser

Testa tips:

```text
precis före en 15-minutersgräns
exakt på gränsen
precis efter gränsen
```

Det ska vara uttryckligt om fönster är:

```text
vänsterinkluderande och högerexkluderande
eller annan vald semantik
```

### 4.3 Flera tips samma sekund

```text
flera giltiga tips med samma epoch_s
→ samtliga lagras
→ ingen primärnyckelkollision
→ rätt ackumulerad mängd
```

### 4.4 Ogiltig logger-tid

```text
time_valid = false
epoch_s saknas
→ mottagartid används enligt ingestregeln
→ kvalitetsflagga visar tidsosäkerhet
```

### 4.5 Räknargap och recovery

```text
checkpoint = 100
nytt state = 105
→ recovery = 5 tips = 1,0 mm
→ time_distribution_uncertain
```

Analystestet ska uttryckligen besluta hur recovery får användas för olika beräkningar:

- ackumulerad totalmängd kan normalt inkludera recovery,
- exakt korttidsfördelning får inte konstrueras,
- fönster som berör recovery ska kvalitetsflaggas eller hanteras enligt versionerad regel.

### 4.6 Dubbletter

```text
samma source_event_key två gånger
→ exakt en observation
→ ingen dubbel mängd
```

### 4.7 Regnhändelser

Testa minst:

```text
en enkel skur
två skurar separerade av kort uppehåll
två händelser separerade av definierat torruppehåll
framtung händelse
baktung händelse
dubbelpeak
```

### 4.8 TB4-specifik korttidsosäkerhet

Fixtures ska kunna representera:

```text
dubbelpuls efter långt uppehåll
tät pulsgrupp mitt i intensivt regn
restvolym vid händelsestart
```

Förväntad kvalitetsklass ska vara en del av testresultatet.

## 5. Testserier och produktionsserier

Analystest ska använda egna serier, exempelvis:

```text
rain.test.analytics.<scenario>
```

De ska ha:

```text
is_test = true
source_type = test_fixture eller motsvarande
resolution_type enligt den modell som testas
```

Den verkliga Nimbus-serien förblir:

```text
rain.sannesholma.nimbus.rain_1.tb4_0p2
is_test = false
```

Testfixtures får inte använda Nimbus produktionsidentitet på ett sätt som gör att de kan blandas ihop med verkliga observationer.

## 6. Resultatisolering och versionering

Analysresultat ska bära minst:

```text
module_name
module_version
input_series_id
calculation_time
quality_rule_version
```

Kandidatversioner ska kunna köras parallellt, exempelvis konceptuellt:

```text
rolling_durations v1 aktiv
rolling_durations v2_candidate skuggkörning
```

Konsumenter får inte automatiskt flyttas till kandidaten.

## 7. Jämförelse vid skuggkörning

Minsta jämförelse mellan aktiv och kandidat:

```text
antal beräknade fönster
ackumulerad mängd
maxvärde per varaktighet
tidpunkt för maxvärde
hantering av tomma perioder
hantering av recovery
kvalitetsflaggor
prestanda
reproducerbar omberäkning
```

Skillnader ska kunna förklaras av en dokumenterad regeländring. Oförklarade skillnader stoppar produktionsväxling.

## 8. Rådata och omberäkning

Råa tip-events är primära observationer och ska inte skrivas om för att passa en beräkningsversion.

```text
rå observation
→ versionerad analys
→ reproducerbart resultat
```

När en algoritm förbättras ska resultat kunna räknas om från rådata.

## 9. Vad den tekniska Nimbus-testtabellen inte är

`hydromet.rain_logger_test_events` är inte:

```text
en permanent analysmiljö
en generell fixturetabell
en IDF-testdatabas
en plats för återkommande manuella vippningar efter produktionssättning
```

Den är:

```text
en teknisk acceptanstabell för den verkliga ingestkedjan före första produktionssättning
```

## 10. Framtida implementation

Den exakta fysiska modellen för fixtures, testserier och versionerade analysresultat ska beslutas när den första TimescaleDB-baserade intensitetsmodulen utformas.

Detta dokument låser ansvar och testprinciper, men låser ännu inte ett specifikt testschema eller tabellnamn.
