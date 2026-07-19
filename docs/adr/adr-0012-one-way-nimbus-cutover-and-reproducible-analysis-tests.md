# ADR-0012: Nimbus går envägs till produktion och analys testas reproducerbart

Status: Antagen  
Datum: 2026-07-19

## Kontext

Nimbus publicerar en gemensam monoton `pulse_total` för den verkliga kanalen:

```text
regnlogger/sannesholma/nimbus/rain_1
```

Den tekniska testinstansen och produktionsinstansen använder samma MQTT-ström och samma loggerägda räknare, men har separata mottagarcheckpoints genom:

```text
(target_table, series_id)
```

Det isolerar lagring, idempotens och mottagartillstånd, men inte själva mätströmmen. När en tidigare aktiverad instans startas igen tolkar den därför varje ökning sedan sin senaste checkpoint som missad nederbörd.

Exempel:

```text
produktionens checkpoint = 120
produktionen stoppas
testvippningar höjer Nimbus pulse_total till 125
produktionen startas igen
```

Produktionen kan då inte skilja testvippningarna från verkligt regn och skulle återvinna differensen som `rain_recovery`.

Samma problem finns åt andra hållet: verkligt produktionsregn som inträffar medan testinstansen är avstängd skulle senare återvinnas i testtabellen.

## Beslut

### 1. Den fysiska Nimbus-testvägen är ett avgränsat acceptanstest

`hydromet.rain_logger_test_events` används för initial teknisk verifiering av:

```text
TB4
→ Nimbus
→ MQTT state + tip
→ AppDaemon
→ idempotens och checkpoint
→ testtabell
```

Testet avslutas med en engångsväxling till produktion.

### 2. Första växlingen till produktion är säker

När produktionsmålet aktiveras första gången saknas en produktionscheckpoint. Aktuellt retained `pulse_total` används då som baseline:

```text
last_seen = NULL
retained pulse_total
→ initial produktionsbaseline
```

Tidigare testvippningar backfylls inte till produktion.

### 3. Efter produktionsbaseline får den verkliga kanalen inte växlas tillbaka

När produktionsmålets första baseline har satts ska den verkliga Nimbus-kanalen stanna i produktion.

Den tekniska testinstansen får finnas kvar som installationsartefakt, men ska inte återaktiveras mot samma `rain_1` och samma `pulse_total` i normal drift.

Återkommande A/B-växling mellan test- och produktionstabell är inte en stödd driftmodell.

### 4. Analys- och beräkningstest använder separata reproducerbara testserier

Utveckling av exempelvis:

```text
rullande 5-, 15-, 30-, 45-, 60-, 120-, 360-, 720- och 1440-minutersvärden
fasta klockfönster
regnhändelser
IDF- och återkomstklassning
kvalitetslogik
recovery-hantering
```

ska inte använda manuella vippningar på den fysiska produktionskanalen som generell testgenerator.

Testdata ska i stället vara deterministiska fixtures med:

```text
egen testserie och eget series_id
kontrollerade tidsstämplar
kontrollerade counters
kända luckor och recoveries
förväntade resultat
```

Beräkningstest ska gå genom samma observations- och analysmodell som produktion, men vara tydligt identifierade som testdata enligt ADR-0009.

### 5. Nya analysversioner får skuggköras read-only mot produktion

En kandidatberäkning får läsa verkliga produktionsobservationer utan att ändra rådata.

Resultat ska hållas versionerade eller isolerade från aktiv produktion, exempelvis:

```text
aktiv analysversion
kandidatversion
```

Jämförelse ska kunna göras av bland annat:

```text
ackumulerad mängd
maximal intensitet
fönstergränser
luckor och recovery
kvalitetsflaggor
prestanda och omberäkning
```

Först efter verifiering får konsumenter flyttas till kandidatversionen.

## Testnivåer

Hydromet skiljer därmed på tre testnivåer:

### Ingest-acceptans

```text
verklig TB4 och Nimbus
→ teknisk testtabell
→ engångsväxling till produktion
```

### Analys- och beräkningstest

```text
syntetiska, reproducerbara testserier
→ samma datamodell och analyskod som produktion
→ kända förväntade resultat
```

### Skuggtest på verklig data

```text
produktionsobservationer, read-only
→ versionerad kandidatberäkning
→ jämförelse utan ändring av rådata
```

## Konsekvenser

### Positiva

- manuella testvippningar kan inte senare förorena produktionen som recovery,
- verkligt produktionsregn kan inte oavsiktligt backfyllas till testtabellen,
- intensitets- och analysberäkningar kan testas deterministiskt,
- råa produktionsobservationer förblir oförändrade och reproducerbara,
- kandidatalgoritmer kan verifieras på verklig data utan produktionspåverkan.

### Begränsningar

- den befintliga fysiska testtabellen är inte en permanent generell utvecklingsmiljö,
- återkommande fysisk end-to-end-test efter produktionssättning kräver en verkligt separat testkanal med egen räknare,
- separat topic räcker inte om samma `pulse_total` fortfarande delas.

## Krav för en framtida fysisk testkanal

En återkommande fysisk testväg måste minst ha:

```text
separat channel_id
separat räknare
separat MQTT-topic
separat series_key
```

Den får inte öka produktionens `rain_1.pulse_total`.

## Ersätter och förtydligar

Detta ADR förtydligar ADR-0009 och ersätter växlingssemantiken i ADR-0011.

ADR-0011 gäller fortsatt för:

```text
tabellparitet
gemensam ingestkod
målspecifik idempotens
målspecifikt mottagartillstånd
första baseline vid produktionssättning
```

Det gäller inte längre som stöd för återkommande växling fram och tillbaka efter produktionssättning.
