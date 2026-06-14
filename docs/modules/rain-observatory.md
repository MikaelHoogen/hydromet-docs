# Regnobservatorium

Status: Första modul / aktiv utveckling

## 1. Syfte

Regnobservatoriet är första konkreta modulen ovanpå hydromet core.

Målet är att bygga lokal regnloggning med:

```text
rådata från mätare
spårbar mätuppställning
normaliserade tidsserier
rullande varaktigheter
IDF-jämförelse
återkomstklassning
regnhändelser
```

## 2. Primära datakällor

```text
TB4/logger_ha
Netatmo cloud
logger_test
framtida regndropps-/regndetekteringssensor
```

## 3. Observationstyper

Tipping bucket-pulser:

```text
hydromet.event_observations
```

Moln/API-intervall:

```text
hydromet.interval_observations
```

Regndetektion:

```text
hydromet.event_observations
eller
hydromet.point_observations
```

## 4. Varaktigheter

Primära varaktigheter:

```text
15, 30, 45, 60, 120, 360, 720, 1440 minuter
```

5 minuter kan finnas som diagnostik/nice-to-have.

## 5. IDF och återkomstklassning

Första metodfamiljer:

```text
SMHI Klimatologi 47
Dahlström 2010
klimatjusterade trösklar
```

Framtida/jämförande:

```text
Dahlström 2018
klimatprediktorbaserad IDF
lokal IDF
```

## 6. Designprincip

```text
Regnanalys byggs ovanpå hydromet core.
Rådata skrivs aldrig över.
Historik ska kunna reklassas när metoder eller trösklar ändras.
```
