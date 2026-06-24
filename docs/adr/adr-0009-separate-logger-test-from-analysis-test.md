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

## Konsekvenser

Detta gör att loggern kan testas isolerat utan risk för produktionsberäkningar, samtidigt som analyskedjan senare kan testas realistiskt i samma modell som produktion.

Nackdelen är att tekniska loggertest inte testar exakt samma insertväg som produktion. Därför behövs även ett senare beräkningstest i ordinarie observationsmodell.

## Designregler

```text
Loggern ska inte behöva veta om körningen är test eller produktion.
```

```text
Tekniska loggertest får isoleras i separat testtabell.
```

```text
Beräkningstest ska gå genom samma datamodell som produktion.
```

```text
Produktionsberäkningar får aldrig läsa från tekniska loggertesttabeller.
```
