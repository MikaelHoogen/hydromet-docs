# ADR-0004: Ingen framåtextrapolerande regnvarning

## Status

Accepted

## Bakgrund

En idé var att systemet skulle kunna visa något i stil med:

```text
Om nuvarande takt fortsätter når vi skyfallsnivå om 35 minuter.
```

Det bedömdes riskera falsk precision och bli mer prognosliknande än observationsbaserat.

## Beslut

Systemet ska inte innehålla framåtextrapolerande regnvarningar baserade på antagandet att aktuell takt fortsätter.

## Tillåtet

Systemet får visa observationsbaserade statusar:

```text
Senaste 15 min motsvarar 82 % av 10-årsnivån.
Senaste 60 min är 76 % av skyfallströskeln.
Mest extrem varaktighet hittills är 30 min.
```

Systemet får också visa bakåtblickande förändring, till exempel return period momentum, så länge det inte extrapolerar framåt.

## Konsekvenser

Fördelar:

- systemet förblir mätbaserat och ärligt,
- lägre risk för missvisande varningar,
- tydligare gräns mellan observation och prognos.

Nackdelar:

- systemet ger inte tidiga prognosliknande indikationer,
- användaren får tolka pågående utveckling utifrån observerade värden.
