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
MQTT-brokern behöver inte känna till databasen.
Databasen behöver inte känna till AppDaemon.
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

## Regnloggerdokumentationens ansvar

Regnloggern beskrivs i flera dokument eftersom hårdvarumodell, installation, loggerbeteende och transportkontrakt är olika saker.

| Fråga | Kanoniskt dokument |
|---|---|
| Hur robust ska Nivå 1 vara och hur ska loggern räkna, filtrera, lagra och återhämta? | [Nivå 1-design för regnlogger](level-1-logger-design.md) |
| Vilka MQTT-topics, payloadfält, schemas och retained-regler gäller? | [MQTT-meddelanden och loggerkontrakt](mqtt-message-contract.md) |
| Hur skiljs `channel_id`, `physical_input` och `hardware_binding` åt? | [Hårdvaruförteckning](../hardware/index.md) |
| Hur är Waveshare-enhetens DI-ingångar kopplade internt? | [Waveshare ESP32-S3 ETH 8DI 8RO](../hardware/waveshare-esp32-s3-eth-8di-8ro.md) |
| Hur är den konkreta loggern Nimbus konfigurerad och vilken mätare sitter på kanalen? | [Regnobservatorium](../modules/rain-observatory.md) |

Rekommenderad läsordning när arbetet återupptas:

```text
Nivå 1-design
→ MQTT-kontrakt
→ hårdvaruförteckning
→ aktuell hårdvarumodell
→ konkret installation
```

För Nimbus ska två olika riktningar hållas isär.

Konfigurations- och uppslagskedjan är:

```text
channel_id rain_1
→ physical_input DI1
→ uppslag i hardware_model waveshare_esp32_s3_eth_8di_8ro
→ hardware_binding GPIO4
→ enhetsspecifik ESPHome-konfiguration
```

Den fysiska signal- och datakedjan är:

```text
TB4
→ DI1 / IN1
→ GPIO4
→ lokal pulsräkning enligt Nivå 1
→ retained state + live tip-event enligt MQTT-kontraktet
→ utbytbar ingest-adapter
→ Hydromet/RainLens datamodell
```

Designregel:

```text
Nivå 1-designen beskriver beteende.
MQTT-kontraktet beskriver kommunikation.
Hårdvaruförteckningen beskriver enhetens fysiska egenskaper.
Regnobservatoriet beskriver den konkreta installationen.
```

Detaljer ska i första hand ändras i sitt kanoniska dokument. Andra dokument får sammanfatta eller ge exempel, men ska hänvisa tillbaka till den kanoniska källan för att minska risken för motstridiga versioner.

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
