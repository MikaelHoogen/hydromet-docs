# Arkitekturöversikt

Status: Arkitektur / målbild

## Syfte

Hydromet-plattformen ska vara en långsiktig observationsplattform för väder, vatten, mark och anläggningsrespons.

Den ska kunna börja mycket konkret med lokal regnloggning, men växa utan att datamodellen behöver göras om.

## Lager

```text
Datakällor
→ MQTT / API / manuella observationer
→ utbytbar ingest-adapter
→ TimescaleDB / PostgreSQL
→ hydromet core
→ domänmoduler
→ Home Assistant / Grafana / rapporter
```

Nuvarande första implementation använder AppDaemon som ingest-adapter mellan MQTT och databasen. Det är ett implementationsval, inte ett kärnberoende.

## Stabilt kontrakt mellan logger och plattform

MQTT-kontraktet är det stabila gränssnittet mellan fysiska loggrar och Hydromet/RainLens.

```text
Logger
→ MQTT-kontrakt
→ valfri ingest-adapter
→ Hydromet/RainLens datamodell
```

Designprinciper:

```text
Loggern behöver inte känna till Home Assistant.
```

```text
MQTT-brokern behöver inte känna till databasen.
```

```text
Databasen behöver inte känna till AppDaemon.
```

```text
Ingest-komponenten är utbytbar.
```

Idag kan kedjan vara:

```text
Logger → MQTT → AppDaemon → TimescaleDB
```

Senare kan samma kontrakt användas med annan ingest:

```text
Logger → MQTT → RainLens ingest → RainLens/Hydromet datamodell
```

Det innebär att Home Assistant och AppDaemon kan vara första driftmiljö och adapter, men inte ska definiera kärnarkitekturen.

## Huvudprincip

```text
Rådata först.
Metadata och mätuppställning tidigt.
Specialiserad analys senare.
Presentation sist.
```

## Hydromet core

Kärnan ska hantera:

```text
observationsserier
mätuppställningar
punktobservationer
intervallobservationer
händelseobservationer
systemhälsa
larm
```

## Moduler

Första modul:

```text
regnobservatorium
```

Möjliga framtida moduler:

```text
nivårespons
flödesrespons
markfukt
vind
vattenkvalitet
anläggningsdrift
```

## Avgränsning

Hydromet ska vara brett nog för väder, vatten, mark och anläggningsrespons, men inte bli en generell plattform för vad som helst.
