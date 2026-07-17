# ADR-0009: Separera loggertest från analys- och beräkningstest

Status: Accepted  
Datum: 2026-06-24

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

Det permanenta parallella Nimbus-testet är ett tekniskt ingesttest av en verklig logger, inte den äldre syntetiska `logger_test`-scenariokällan.

För Nimbus gäller enligt [ADR-0011](adr-0011-nimbus-parallel-test-production-ingest.md):

```text
verklig Nimbus MQTT
→ samma AppDaemon-implementation
→ testtabell eller produktionstabell
```

Test- och produktionstabellen ska ha samma struktur, constraints, hypertable-upplägg och indexform. AppDaemon-instansierna ska vara identiska bortsett från `target_table`.

Nimbus använder samma verkliga `observation_series` och aktiva `measurement_setup` i båda målen. Isoleringen sker genom måltabellen, inte genom att den verkliga Nimbus-serien märks som syntetisk testserie.

Detta förtydligande ersätter inte regeln att analys- och beräkningstest ska använda ordinarie observationsmodell med `is_test = true`. Det gäller endast den tekniska parallella Nimbus-ingesten.

## Konsekvenser

Detta gör att loggern kan testas isolerat utan risk för produktionsberäkningar, samtidigt som analyskedjan senare kan testas realistiskt i samma modell som produktion.

Nackdelen är att tekniska loggertest inte testar exakt samma tabellnamn som produktion. För Nimbus reduceras denna skillnad genom att tabellerna hålls strukturellt identiska och samma ingestkod används för båda målen.

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
Beräkningstest ska gå genom samma datamodell som produktion.
```

```text
Produktionsberäkningar får aldrig läsa från tekniska loggertesttabeller.
```
