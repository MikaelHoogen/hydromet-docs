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

## Regnlogger: läs i denna ordning

Dokumentationen för Nimbus och Nivå 1 är uppdelad efter ansvar. Börja här när arbetet återupptas efter ett avbrott:

1. [Nivå 1-design för regnlogger](architecture/level-1-logger-design.md) — loggerns beteende, räknare, debounce, persistens, återhämtning och test.
2. [MQTT-meddelanden och loggerkontrakt](architecture/mqtt-message-contract.md) — kanoniska topics, payloadfält, scheman och retained-regler.
3. [Hårdvaruförteckning](hardware/index.md) — gränsen mellan `channel_id`, `physical_input` och `hardware_binding`.
4. [Waveshare ESP32-S3 ETH 8DI 8RO](hardware/waveshare-esp32-s3-eth-8di-8ro.md) — den aktuella modellens ingångar och interna GPIO-bindningar.
5. [Regnobservatorium](modules/rain-observatory.md) — den konkreta Nimbus-installationen och regnmodulens fortsatta användning av data.

Ansvarsfördelningen är:

```text
Nivå 1-design   = hur loggern beter sig
MQTT-kontrakt   = hur loggern kommunicerar
Hårdvarumodell  = vad enheten fysiskt har
Installation    = hur Nimbus är kopplad
Regnobservatorium = hur observationerna används i domänen
```

För Nimbus blir den fysiska kedjan:

```text
TB4
→ DI1 / IN1 på Waveshare-enheten
→ GPIO4 enligt hårdvaruförteckningen
→ channel_id rain_1
→ retained state + live tip-event enligt Nivå 1
→ utbytbar ingest-adapter
→ Hydromet/RainLens datamodell
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
