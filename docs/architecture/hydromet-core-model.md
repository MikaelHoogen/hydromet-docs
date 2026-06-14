# Hydromet kärnmodell

Status: Arkitektur / målbild

## 1. Grundidé

Regnobservatoriet är första modulen, men grundplattformen ska kunna bära fler typer av hydrometeorologiska och hydrauliska observationer.

Målbild:

```text
hydromet-plattform
→ regn
→ nivå
→ flöde
→ markfukt
→ vind
→ regndetektion
→ vattenkvalitet
→ framtida sensorer och dataklasser
```

Kärnmodellen ska inte vara låst till regn, IDF eller tipping bucket.

## 2. Modellprincip

Datamodellen delas i två lager:

```text
hydromet core
→ generella serier, mätuppställningar, observationer och systemhälsa

moduler
→ regn, nivårespons, flöde, markfukt, vind, vattenkvalitet m.m.
```

Det betyder:

```text
Alla sensorer är observationsserier.
Alla observationsserier har metadata.
Alla observationer är tidsatta.
Mätuppställningar är versionerade.
Specialiserad analys byggs ovanpå kärnmodellen.
```

## 3. Föreslagna kärntabeller

```text
hydromet.observation_series
hydromet.measurement_setups
hydromet.point_observations
hydromet.interval_observations
hydromet.event_observations
hydromet.system_health
hydromet.system_alerts
```

## 4. Observationsserie

En observationsserie beskriver vad som mäts, var, hur och med vilken typ av källa.

Exempel:

```text
tb4_logger_ha
netatmo_cloud
pond_1_level
pond_1_outflow
well_1_level
well_1_outflow
soil_moisture_field_1
rain_drop_sensor_1
wind_station_1_speed
wind_station_1_direction
```

Viktiga fält:

```text
series_id
series_key
observed_property
medium
location_key
location_type
unit
source_type
resolution_type
is_primary
is_active
created_at
metadata
```

## 5. Mätuppställning

En mätuppställning beskriver fysisk och teknisk konfiguration under en viss tidsperiod.

Viktiga fält:

```text
setup_id
series_id
valid_from
valid_to
instrument_model
sensor_type
installation_description
mounting_height_m
reference_level
logger_type
firmware
notes
metadata
```

Detta gör att en serie kan byta givare, placering, firmware eller kalibrering utan att historiken blandas ihop.

## 6. Observationstyper

Alla data passar inte i en enda observationstabell.

Kärnmodellen skiljer därför på:

```text
point_observations
interval_observations
event_observations
```

### Punktobservationer

Passar för:

```text
nivå
flöde
markfukt
vindhastighet
vindriktning
temperatur
batteri
signalstyrka
```

Viktiga fält:

```text
time
received_at
series_id
setup_id
value
unit
quality_flag
raw_payload
metadata
```

### Intervallobservationer

Passar för:

```text
Netatmo cloud-regn per intervall
summerat regn per 5 min
medelvind per intervall
ackumulerad nederbörd per intervall
```

Viktiga fält:

```text
interval_start
interval_end
received_at
series_id
setup_id
value
unit
aggregation
quality_flag
raw_payload
metadata
```

### Händelseobservationer

Passar för:

```text
tipping bucket-puls
regn_start
regn_stop
regndropp detekterad
nivålarm
flödeslarm
logger restart
pump_start
pump_stop
```

Viktiga fält:

```text
time
received_at
series_id
setup_id
event_type
value
unit
counter
quality_flag
raw_payload
metadata
```

## 7. Observed properties

`observed_property` ska vara stabilt och maskinläsbart.

Exempel:

```text
precipitation
precipitation_tip
precipitation_interval
precipitation_presence
water_level
discharge
soil_moisture
wind_speed
wind_direction
wind_gust
air_temperature
relative_humidity
air_pressure
solar_radiation
water_temperature
conductivity
turbidity
battery_voltage
signal_strength
system_status
```

Visningsnamn kan vara svenska i Home Assistant/Grafana.

## 8. Designregler

```text
Bygg inte en databas som bara förstår regn.
```

```text
Regn är första modulen, inte hela plattformen.
```

```text
Nya sensortyper ska kunna dockas på som observationsserier.
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
