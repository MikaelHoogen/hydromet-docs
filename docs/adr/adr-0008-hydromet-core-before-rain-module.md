# ADR-0008: Hydromet core byggs före regnmodul

Status: Accepted  
Datum: 2026-06-14

## Kontext

Projektet började som ett lokalt regn- och skyfallsobservatorium.

Under planeringen blev det tydligt att systemet på sikt även behöver kunna hantera:

```text
flöde i damm
nivå i damm
flöde från brunn
nivå i brunn
markfukt
regndetektering
vind
vattenkvalitet
andra framtida sensorer och dataklasser
```

Det handlar alltså inte bara om fler sensorer, utan om fler klasser av data.

## Beslut

Datamodellen ska utgå från en generell hydromet-kärna.

Regnobservatoriet ska vara första modul ovanpå denna kärna, inte hela grundarkitekturen.

Första SQL-steget ska därför vara ett generellt `hydromet`-schema.

Målbild:

```text
hydromet.observation_series
hydromet.measurement_setups
hydromet.point_observations
hydromet.interval_observations
hydromet.event_observations
hydromet.system_health
hydromet.system_alerts
```

Regnspecifik analys byggs därefter ovanpå:

```text
hydromet.rain_duration_values
hydromet.idf_thresholds
hydromet.rain_return_period_results
hydromet.rain_events
```

## Konsekvenser

Positiva konsekvenser:

```text
nya sensortyper kan dockas på senare
nya dataklasser kan läggas till utan ny grundarkitektur
regn, nivå, flöde, markfukt, vind och vattenkvalitet kan samexistera
mätuppställningar och metadata blir generella
systemhälsa kan användas för alla loggrar
regnspecifik analys kan utvecklas utan att låsa kärnmodellen
```

Negativa konsekvenser:

```text
första SQL-steget blir något mer abstrakt
AppDaemon behöver mappa topics till observation_series, inte bara till rain-tabeller
regnmodulen behöver bygga vyer eller specialtabeller ovanpå kärntabellerna
nya dataklasser behöver definieras med observed_property, unit, resolution_type och metadata
```

## Designregler

```text
Bygg inte en databas som bara förstår regn.
```

```text
Regn är första modulen, inte hela plattformen.
```

```text
Nya sensortyper ska läggas till som observationsserier, inte genom ny grundarkitektur.
```

```text
Nya dataklasser ska kunna läggas till utan ny grundarkitektur.
```

```text
Specialiserad analys ska byggas ovanpå generella observationer.
```

```text
Rådata ska alltid sparas med källa, tid, serie, mätuppställning och raw_payload.
```

```text
Hydromet ska vara brett nog för väder, vatten, mark och anläggningsrespons, men inte bli en generell plattform för vad som helst.
```
