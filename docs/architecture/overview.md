# Arkitekturöversikt

Status: Arkitektur / målbild

## Syfte

Hydromet-plattformen ska vara en långsiktig observationsplattform för väder, vatten, mark och anläggningsrespons.

Den ska kunna börja mycket konkret med lokal regnloggning, men växa utan att datamodellen behöver göras om.

## Lager

```text
Datakällor
→ MQTT / API / manuella observationer
→ AppDaemon / ingest
→ TimescaleDB / PostgreSQL
→ hydromet core
→ domänmoduler
→ Home Assistant / Grafana / rapporter
```

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
