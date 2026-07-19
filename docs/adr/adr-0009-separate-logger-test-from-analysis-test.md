# ADR-0009: Separera loggertest från analys- och beräkningstest

Status: Accepted  
Datum: 2026-06-24  
Förtydligat: 2026-07-19 genom [ADR-0012](adr-0012-one-way-nimbus-cutover-and-reproducible-analysis-tests.md)

## Kontext

Hydromet behöver skilja på två typer av test:

```text
loggertest = teknisk verifiering av ESP, MQTT, pulsnummer, AppDaemon och databasskrivning
beräkningstest = verifiering av varaktigheter, händelser, IDF, återkomsttid och analyslogik
```

## Beslut

Loggern får bete sig som produktion även under verifiering. Den kan använda produktionsmässigt MQTT-topic och produktionsmässig identitet.

AppDaemon avgör om inkommande pulser skrivs till en teknisk testtabell eller till den ordinarie observationsmodellen.

Tekniska loggertest får använda separat testtabell, exempelvis:

```text
hydromet.rain_logger_test_events
```

Den tabellen ska inte användas för regnanalys, IDF, återkomsttid eller produktionsstatistik.

Analys- och beräkningstest ska däremot gå genom samma modell som produktion, men märkas tydligt, exempelvis:

```text
is_test = true
series_key = rain.test.<sensor>.<logger>
```

Produktion använder motsvarande produktionsserie:

```text
is_test = false
series_key = rain.<sensor>.<logger>
```

## Förtydligande för verkliga Nimbus

Det parallella Nimbus-testet är ett tekniskt ingesttest av en verklig logger, inte den äldre syntetiska `logger_test`-scenariokällan.

För Nimbus gäller enligt [ADR-0011](adr-0011-nimbus-parallel-test-production-ingest.md) och [ADR-0012](adr-0012-one-way-nimbus-cutover-and-reproducible-analysis-tests.md):

```text
verklig Nimbus MQTT
→ samma AppDaemon-implementation
→ initial teknisk testtabell
→ engångsväxling till produktion
```

Test- och produktionstabellen ska ha samma struktur, constraints, hypertable-upplägg och indexform. AppDaemon-instansierna ska vara identiska bortsett från `target_table`.

Nimbus använder samma verkliga `observation_series` och aktiva `measurement_setup` i båda målen. Isoleringen sker genom måltabellen, inte genom att den verkliga Nimbus-serien märks som syntetisk testserie.

Eftersom båda målen följer samma loggerägda monotona `pulse_total` är måltabellen inte en fullständig isolering av mätströmmen. Efter att produktionsmålets första baseline har satts får den verkliga Nimbus-kanalen därför inte växlas återkommande tillbaka till testmålet.

Detta förtydligande ersätter inte regeln att analys- och beräkningstest ska använda ordinarie observationsmodell med `is_test = true`. Det gäller endast den tekniska Nimbus-ingestens acceptans och första produktionssättning.

## Reproducerbara analys- och beräkningstest

Analysmoduler ska testas med deterministiska testserier, inte med manuella vippningar på den fysiska produktionskanalen.

Testserier ska kunna beskriva:

```text
kontrollerade tip-tider
kontrollerade counters
fönstergränser
räknarhopp och recovery
ogiltig eller saknad tid
förväntade 5-, 15-, 30-, 45-, 60-, 120-, 360-, 720- och 1440-minutersresultat
förväntade händelser och kvalitetsflaggor
```

De ska ha egna testidentiteter och vara tydligt åtskilda från produktion, men gå genom samma datamodell och beräkningskod som produktion.

Nya analysversioner får dessutom skuggköras read-only mot verkliga produktionsobservationer. Resultaten ska vara versionerade eller isolerade så att kandidatalgoritmen kan jämföras utan att rådata eller aktiva produktionsresultat ändras.

## Tre testnivåer

```text
1. Ingest-acceptans
   verklig logger → teknisk testtabell → engångsväxling till produktion

2. Analys- och beräkningstest
   reproducerbara testserier → samma modell och kod som produktion

3. Skuggtest på verklig data
   produktionsrådata read-only → kandidatversion → jämförelse
```

## Konsekvenser

Detta gör att loggern kan testas isolerat före produktionssättning, samtidigt som analyskedjan senare kan testas realistiskt och reproducerbart i samma modell som produktion.

Nackdelen är att tekniska loggertest inte testar exakt samma tabellnamn som produktion. För Nimbus reduceras denna skillnad genom att tabellerna hålls strukturellt identiska och samma ingestkod används för båda målen.

Den tekniska Nimbus-testtabellen är inte en permanent generell utvecklingsdatabas för intensitetsberäkningar, IDF eller andra analysmoduler.

## Designregler

```text
Loggern ska inte behöva veta om körningen är test eller produktion.
```

```text
Tekniska loggertest får isoleras i separat testtabell.
```

```text
Nimbus tekniska test- och produktionstabell ska vara strukturella speglar.
```

```text
Den verkliga Nimbus-kanalen går envägs från ingest-acceptans till produktion.
```

```text
Beräkningstest ska gå genom samma datamodell som produktion med separata reproducerbara testserier.
```

```text
Produktionsrådata får användas read-only för versionerade skuggtester.
```

```text
Produktionsberäkningar får aldrig läsa från tekniska loggertesttabeller.
```
