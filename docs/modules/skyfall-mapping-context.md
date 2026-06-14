# Koppling till skyfallskartering

Status: Framtida konsekvens- och scenariolager

## Syfte

Modulen ska på sikt kunna koppla uppmätta regnhändelser till skyfallskarteringsscenarier, modellregn och praktisk konsekvensförståelse.

## Exempel på framtida objekt

```text
mapping_scenarios
event_mapping_comparison
manual_effect_observations
scenario_metadata
model_rain_metadata
```

## Möjliga jämförelser

```text
uppmätt regn jämfört med modellregn
uppmätt händelse jämfört med skyfallsscenario
observerad effekt jämfört med beräknad konsekvens
```

## Designregel

```text
Kopplingen till skyfallskartering ska inte ersätta mät- och IDF-kärnan.
Den ska vara ett analyslager ovanpå observerade händelser.
```
