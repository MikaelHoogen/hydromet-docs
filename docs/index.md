# Hydromet Docs

Detta är den levande dokumentationen för en modulär hydromet-plattform.

Plattformen ska kunna bära observationer av:

```text
atmosfär
nederbörd
mark
hydraulik
vattenkvalitet
systemhälsa
```

Regnobservatoriet är första konkreta modulen, men grundmodellen ska inte vara låst till regn.

## Grundprincip

```text
Rådata är stabil.
Metadata är spårbar.
Mätuppställningar är versionerade.
Analys är modulär.
Presentation är separerad från datalagring.
```

## Relation till Home Assistant

Home Assistant-repot är implementation och drift:

```text
ESPHome
AppDaemon
MQTT
Home Assistant dashboards
TimescaleDB-integration
```

Detta repo är metod och arkitektur:

```text
datamodell
observationsdomäner
SQL-plan
loggerkontrakt
ADR
roadmap
källor
```

## Första målbild

```text
hydromet core
→ observation_series
→ measurement_setups
→ point_observations
→ interval_observations
→ event_observations
→ system_health
→ regnmodul
```
