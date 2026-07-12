# MQTT-meddelanden och loggerkontrakt

Status: Kanoniskt kontrakt för Nivå 1 / delvis implementerat

## 1. Syfte och dokumentgräns

Detta dokument är styrande för MQTT-topics, meddelandetyper, retained-regler och payloadfält mellan en logger och en ingest-adapter.

Det beskriver inte:

- hur en viss fysisk ingång är kopplad internt i en hårdvarumodell
- hur en konkret loggerinstallation är kabelansluten
- den fullständiga ESPHome-implementationen
- analys- eller databaslogik utöver kontraktets gräns

Relaterade styrande dokument:

- [Nivå 1-design för regnlogger](level-1-logger-design.md) beskriver loggerbeteende, återhämtning och test.
- [Hårdvaruförteckningen](../hardware/index.md) beskriver `physical_input` och `hardware_binding`.
- [Regnobservatoriet](../modules/rain-observatory.md) beskriver Nimbus-installationen.

## 2. MQTT som stabilt gränssnitt

MQTT-kontraktet är ett stabilt gränssnitt mellan fysisk logger och Hydromet/RainLens.

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

Nuvarande kedja kan vara:

```text
MQTT → AppDaemon → TimescaleDB
```

Framtida kedja kan vara:

```text
MQTT → RainLens ingest → Hydromet/RainLens datamodell
```

Så länge loggern publicerar enligt topic- och payloadkontraktet ska mottagaren kunna bytas utan att loggern behöver ändras.

## 3. Identiteter

Kontraktet skiljer på plats, fysisk logger, logisk kanal och mätare.

```text
site_id     = plats eller anläggning, t.ex. sannesholma
logger_id   = fysisk loggerenhet, t.ex. nimbus
channel_id  = logisk mätkanal i loggern, t.ex. rain_1
sensor_id   = ansluten mätare eller sensor, t.ex. tb4_0p2
```

Designregler:

```text
Loggern är inte samma sak som mätaren.
Kanalidentiteten är inte samma sak som fysisk plint eller intern GPIO.
```

En logger kan ha flera kanaler och flera anslutna mätare. Mätartyp ska därför inte bakas in i loggerns identitet.

## 4. Kanal och hårdvaruabstraktion

`channel_id` är den stabila identiteten i RainLens/Hydromet-kontraktet.

```text
channel_id       = stabil kanalidentitet i kontraktet
physical_input   = fysisk ingång på vald hårdvarumodell
hardware_binding = hårdvarumodellens interna tekniska koppling
```

För Nimbus:

```text
rain_1
→ DI1 / IN1
→ GPIO4 på Waveshare-modellen
```

I detta exempel är `rain_1` kontraktet, `DI1` installationens fysiska ingång och `GPIO4` hårdvarumodellens interna bindning.

`physical_input`, GPIO-nummer, Modbus-adress eller andra interna bindningar ska normalt inte skickas i varje observation. De hör hemma i installationens metadata och hårdvaruförteckningen.

## 5. Kanonisk topic-struktur

Loggerövergripande topics:

```text
regnlogger/<site_id>/<logger_id>/status
regnlogger/<site_id>/<logger_id>/heartbeat
```

Kanalövergripande topics:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/state
regnlogger/<site_id>/<logger_id>/<channel_id>/tip
```

Exempel för Nimbus:

```text
regnlogger/sannesholma/nimbus/status
regnlogger/sannesholma/nimbus/heartbeat
regnlogger/sannesholma/nimbus/rain_1/state
regnlogger/sannesholma/nimbus/rain_1/tip
```

Tolkning:

```text
regnlogger  = system/familj
sannesholma = site_id
nimbus      = logger_id
rain_1      = channel_id
state/tip   = message_type
```

Mätaridentiteten ligger i payloaden och är inte en topic-nivå som definierar hela loggern.

## 6. Meddelandetyper och retained-regler

| Meddelande | Nivå | Retained | Publicering | Funktion |
|---|---|---:|---|---|
| `status` | logger | Ja | birth/will och anslutningsförändring | Snabb online/offline-status |
| `heartbeat` | logger | Normalt nej | Periodiskt | Hälsa, tid, uptime, firmware och kanalöversikt |
| `state` | kanal | Ja | Vid accepterad puls samt periodiskt | Senaste ackumulerade kanalläge och återhämtningspunkt |
| `tip` | kanal | Nej | Vid varje accepterad puls | Live-event med bästa tillgängliga tid |

Grundregel:

```text
state och tip kompletterar varandra.
```

`tip` ger tidsupplöst information. `state` gör att ackumulerad mängd kan jämföras och delvis återhämtas om live-events saknas.

## 7. Status

`status` är loggerövergripande och ska vara retained.

Topic:

```text
regnlogger/<site_id>/<logger_id>/status
```

Payload:

```text
online
offline
```

Rekommenderad användning:

- MQTT birth publicerar `online` retained.
- MQTT last will publicerar `offline` retained.
- Kontrollerad nedstängning får publicera `offline` retained.

Status ersätter inte heartbeat. Den visar anslutningsläge, inte full systemhälsa.

## 8. Channel state

`state` är kanalens senaste kända ackumulerade läge och ska vara retained.

Schema:

```text
rainlens.logger.channel_state.v1
```

Exempel:

```json
{
  "schema": "rainlens.logger.channel_state.v1",
  "site_id": "sannesholma",
  "logger_id": "nimbus",
  "channel_id": "rain_1",
  "sensor_id": "tb4_0p2",
  "sensor_type": "tipping_bucket",
  "mm_per_tip": 0.2,
  "pulse_total": 12345,
  "raw_pulse_total": 12350,
  "ignored_pulse_total": 5,
  "rain_total_mm": 2469.0,
  "last_tip_epoch_s": 1782840000,
  "last_tip_uptime_ms": 12345678,
  "time_valid": true,
  "uptime_ms": 12350000,
  "boot_count": 7,
  "firmware": "rainlens-field-prototype-v1",
  "faults": []
}
```

Minimikrav:

- `schema`
- `site_id`
- `logger_id`
- `channel_id`
- `sensor_id`
- `mm_per_tip`
- `pulse_total`
- `rain_total_mm`
- `time_valid`
- `uptime_ms`

Rekommenderade fält:

- `sensor_type`
- `raw_pulse_total`
- `ignored_pulse_total`
- `last_tip_epoch_s`
- `last_tip_uptime_ms`
- `boot_count`
- `firmware`
- `faults`

`state` ska publiceras vid varje accepterad puls och dessutom periodiskt. Periodisk publicering gör att mottagaren får en ny kontrollpunkt även när ett tidigare state-meddelande har missats eller brokern har startats om utan bevarad retained-databas.

## 9. Tip-event

`tip` representerar en enskild accepterad vippning och ska inte vara retained.

Schema:

```text
rainlens.logger.tip_event.v1
```

Exempel:

```json
{
  "schema": "rainlens.logger.tip_event.v1",
  "site_id": "sannesholma",
  "logger_id": "nimbus",
  "channel_id": "rain_1",
  "sensor_id": "tb4_0p2",
  "sensor_type": "tipping_bucket",
  "event": "rain_tip",
  "mm": 0.2,
  "pulse_total": 12345,
  "raw_pulse_total": 12350,
  "ignored_pulse_total": 5,
  "interval_ms": 35892,
  "epoch_s": 1782840000,
  "uptime_ms": 12345678,
  "time_valid": true
}
```

Minimikrav:

- `schema`
- `site_id`
- `logger_id`
- `channel_id`
- `sensor_id`
- `event`
- `mm`
- `pulse_total`
- `uptime_ms`
- `time_valid`

Rekommenderade fält:

- `sensor_type`
- `raw_pulse_total`
- `ignored_pulse_total`
- `interval_ms`
- `epoch_s` när tiden är giltig

## 10. Heartbeat

Heartbeat är loggerövergripande och bör publiceras periodiskt, exempelvis var 30:e eller 60:e sekund.

Schema:

```text
rainlens.logger.heartbeat.v1
```

Exempel:

```json
{
  "schema": "rainlens.logger.heartbeat.v1",
  "site_id": "sannesholma",
  "logger_id": "nimbus",
  "status": "online",
  "uptime_ms": 12350000,
  "boot_count": 7,
  "time_valid": true,
  "network": "ethernet",
  "hardware_model": "waveshare_esp32_s3_eth_8di_8ro",
  "channels": {
    "rain_1": {
      "sensor_id": "tb4_0p2",
      "pulse_total": 12345,
      "raw_pulse_total": 12350,
      "ignored_pulse_total": 5,
      "last_tip_epoch_s": 1782840000,
      "last_tip_uptime_ms": 12345678
    }
  },
  "firmware": "rainlens-field-prototype-v1",
  "faults": []
}
```

Heartbeat ska kunna användas för att upptäcka:

- utebliven kontakt trots att retained status fortfarande visar `online`
- reboot genom ändrad `boot_count` eller lägre `uptime_ms`
- ogiltig tid
- räknaravvikelse
- logger- eller kanalrelaterade fel

## 11. Räknarsemantik

```text
raw_pulse_total      = alla detekterade pulser
pulse_total          = accepterade pulser efter filter
ignored_pulse_total  = bortfiltrerade pulser
```

`pulse_total` är loggerns lokala, logiskt monotona räknare för accepterade pulser och den bästa tillgängliga sanningen för ackumulerad Nivå 1-data.

Den används för att:

- upptäcka saknade live-events
- identifiera dubbletter
- beräkna saknad ackumulerad mängd
- upptäcka räknarregression efter reboot eller persistensproblem

Ett räknarhopp får inte omvandlas till påhittade tip-tider. Mängden kan återhämtas, men tidsfördelningen ska markeras som osäker.

## 12. Tidshantering

```text
uptime_ms skickas alltid.
time_valid skickas alltid.
epoch_s skickas bara när tid är giltig.
```

Om tiden inte är giltig:

```json
{
  "time_valid": false,
  "epoch_s": null
}
```

`epoch_s` får också utelämnas när `time_valid` är `false`.

Viktig regel:

```text
Loggern får inte publicera falsk UTC-tid som ser giltig ut.
```

## 13. Ingest-kontrakt

Ingest-adaptern ska använda kombinationen:

```text
MQTT topic + site_id + logger_id + channel_id + sensor_id
```

för att mappa till:

```text
observation_series
→ aktiv measurement_setup
→ event_observations / interval_observations / point_observations
```

För tipping bucket-data ska ingest-adaptern:

- skriva normala live-tips som händelseobservationer
- jämföra `tip.pulse_total` och `state.pulse_total` med senast kända räknare
- undvika dubbelräkning
- flagga räknarhopp och räknarregression
- kunna återvinna saknad ackumulerad mängd utan att konstruera exakta tip-tider

Fullständig återhämtningslogik beskrivs i [Nivå 1-designen](level-1-logger-design.md).

## 14. Databasprincip

Tip-meddelanden från tipping bucket skrivs som händelseobservationer:

```text
hydromet.event_observations
```

Tekniska loggertest kan enligt ADR-0009 skrivas till:

```text
hydromet.rain_logger_test_events
```

Moln-/API-regn per tidsintervall skrivs som intervallobservationer:

```text
hydromet.interval_observations
```

Status, heartbeat och kanalhälsa hör till:

```text
hydromet.system_health
hydromet.system_alerts
```

Återhämtad mängd från ett räknarhopp ska lagras med kvalitetsinformation som visar att den exakta tidsfördelningen är okänd.

## 15. Historiskt kontrakt: logger_ha

Befintlig logger publicerar accepterade regnpulser som JSON på:

```text
regnlogger/tb4/logger_ha/tip
```

och birth/will-status på:

```text
regnlogger/tb4/logger_ha/status
```

Detta är ett historiskt kompatibilitetsspår. Det får fortsätta fungera under övergången, men nya Nivå 1-loggrar ska använda det kanoniska kontraktet med loggerövergripande `status` och `heartbeat` samt kanalövergripande `state` och `tip`.
