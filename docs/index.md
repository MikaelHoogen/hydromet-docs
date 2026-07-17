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
hårdvarumodeller
installationsdokumentation
runbooks
ADR
roadmap
källor
```

## Regnlogger: läs i denna ordning

Dokumentationen för Nimbus och Nivå 1 är uppdelad efter ansvar. Börja här när arbetet återupptas efter ett avbrott:

1. [Nivå 1-design för regnlogger](architecture/level-1-logger-design.md) — loggerns beteende, räknare, debounce, persistens, återhämtning och test.
2. [MQTT-meddelanden och loggerkontrakt](architecture/mqtt-message-contract.md) — kanoniska topics, payloadfält, scheman och retained-regler.
3. [Hårdvaruförteckning](hardware/index.md) — gränsen mellan `channel_id`, `physical_input`, `field_return` och `hardware_binding`.
4. [Waveshare ESP32-S3-POE-ETH-8DI-8DO](hardware/waveshare-esp32-s3-poe-eth-8di-8do.md) — den exakta modellens plintar, isolerade ingång, `DI1–DGND`, GPIO4 och pull-up.
5. [Sännesholma Nimbus](installations/sannesholma-nimbus.md) — den konkreta installationen och skillnaden mellan aktiv driftkonfiguration, referensimplementation och målkonfiguration.
6. [Verifiering av Nimbus DI1-ingång](runbooks/nimbus-di1-verification.md) — bänktest, bygeltest, störningstest och acceptanskriterier.
7. [Regnobservatorium](modules/rain-observatory.md) — hur observationerna används i regndomänen.

Ansvarsfördelningen är:

```text
Nivå 1-design      = hur loggern beter sig
MQTT-kontrakt      = hur loggern kommunicerar
Hårdvarumodell     = vad enheten fysiskt har
Installation       = hur Nimbus faktiskt är kopplad
Aktiv HA-konfig    = vad ESPHome faktiskt är avsedd att köra
Runbook            = hur funktionen verifieras
Regnobservatorium  = hur observationerna används i domänen
```

För Nimbus blir den fysiska kedjan:

```text
KISTERS TB4 potentialfri kontakt
→ DI1 och DGND på Waveshare-enheten
→ GPIO4 enligt hårdvaruförteckningen
→ definierad GPIO-vilonivå med pull-up
→ channel_id rain_1
→ retained state + live tip-event enligt Nivå 1
→ utbytbar ingest-adapter
→ Hydromet/RainLens datamodell
```

## Aktiv konfiguration kontra referensimplementation

```text
Aktiv driftkonfiguration:
MikaelHoogen/home-assistant/esphome/regnlogger-nimbus.yaml

Referensimplementation:
MikaelHoogen/hydromet-core/deployments/sannesholma/nimbus/esphome.yaml
```

Dessa filer får inte behandlas som samma källa. Aktiv drift verifieras mot Home Assistant-repot och en dokumenterad Git-commit.

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
