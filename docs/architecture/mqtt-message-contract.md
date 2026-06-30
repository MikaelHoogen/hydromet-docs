# MQTT-meddelanden och loggerkontrakt

Status: Målbild / delvis nuläge

## 1. Syfte

Loggerkontraktet ska göra det tydligt hur mätare, loggrar, MQTT, ingest-adapter och databas hänger ihop.

Målet är att rådata ska kunna lagras robust, med spårbar källa och tillräcklig diagnostik.

Detta dokument ska läsas tillsammans med:

- `architecture/logger-reliability-levels.md`
- `adr/adr-0010-rain-logger-reliability-levels.md`
- `architecture/system-health.md`

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

Nuvarande implementation kan vara:

```text
MQTT → AppDaemon → TimescaleDB
```

Framtida implementation kan vara:

```text
MQTT → RainLens ingest → Hydromet/RainLens datamodell
```

Så länge loggern publicerar enligt topic- och payload-kontraktet ska mottagaren kunna bytas utan att loggern behöver ändras.

Viktig begränsning:

```text
MQTT är transport, inte system of record.
```

För Nivå 1-loggers är loggerns lokala monotona räknare den bästa tillgängliga sanningen för ackumulerad rå pulsdata. För Nivå 2-loggers blir loggerns lokala journal system of record tills backend har bekräftat mottagna events.

## 3. Identiteter

Loggerkontraktet ska skilja på plats, fysisk logger, kanal och mätare.

```text
site_id     = plats eller anläggning, t.ex. sannesholma
logger_id   = fysisk loggerenhet, t.ex. nimbus
channel_id  = fysisk/logisk ingång på loggern, t.ex. rain_1
sensor_id   = ansluten mätare eller sensor, t.ex. tb4_0p2
```

Designregel:

```text
Loggern är inte samma sak som mätaren.
```

En fysisk logger kan senare ha flera kanaler och flera anslutna mätare. Därför ska mätartyp inte bakas in i loggerns identitet.

## 4. Nuvarande logger_ha

Befintlig logger publicerar accepterade regnpulser som JSON.

```text
regnlogger/tb4/logger_ha/tip
```

Befintlig logger har också MQTT birth/will-status:

```text
regnlogger/tb4/logger_ha/status
```

Statusvärden:

```text
online
offline
```

Nuläge:

```text
tip-topic med JSON vid accepterad puls
status-topic med retained online/offline
inget periodiskt JSON-heartbeat ännu
```

Detta är historiskt nuläge och får fortsätta fungera. Ny logger ska följa den nya logger- och platscentrerade strukturen.

Historisk `logger_ha` ska betraktas som Nivå 0 eller tidig Nivå 1 beroende på faktisk implementation. Den ska inte betraktas som produktionslogger utan kompletterande state, diagnostik och luckdetektering.

## 5. Ny topic-struktur

Ny målbild för topics:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/<message_type>
```

Exempel:

```text
regnlogger/sannesholma/nimbus/rain_1/state
regnlogger/sannesholma/nimbus/rain_1/tip
regnlogger/sannesholma/nimbus/rain_1/heartbeat
```

För loggerövergripande status kan även denna nivå användas:

```text
regnlogger/sannesholma/nimbus/status
regnlogger/sannesholma/nimbus/heartbeat
```

Rekommenderad tolkning:

```text
regnlogger  = system/familj
sannesholma = site_id
nimbus      = logger_id
rain_1      = channel_id
state       = message_type
```

Mätaridentiteten ska ligga i payloaden, inte användas som topic-nivå som styr hela loggern.

## 6. State och event

Från och med Nivå 1 ska loggerkontraktet skilja tydligt mellan **state** och **event**.

```text
state = senaste kända tillstånd, retained, används för återhämtning
event = enskild händelse, inte retained, används för tidsupplöst mätserie
```

Detta är den viktigaste praktiska konsekvensen av loggernivåmodellen.

### 6.1 State

State publiceras per kanal och ska vara retained.

Topic:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/state
```

State ska innehålla den senaste räknarställningen. Den ska kunna användas av ingest-adapter eller AppDaemon för att upptäcka om events har missats.

Exempelpayload:

```json
{
  "schema": "rainlens.logger.channel_state.v1",
  "site_id": "sannesholma",
  "logger_id": "nimbus",
  "channel_id": "rain_1",
  "sensor_id": "tb4_0p2",
  "sensor_type": "tipping_bucket",
  "mm_per_tip": 0.2,
  "pulse_total": 123,
  "raw_pulse_total": 123,
  "ignored_pulse_total": 0,
  "rain_total_mm": 24.6,
  "last_tip_at_epoch_s": 1782840000,
  "time_valid": true,
  "uptime_ms": 12345678,
  "boot_count": 4,
  "faults": []
}
```

Minimikrav för Nivå 1:

```text
pulse_total
mm_per_tip
rain_total_mm
time_valid eller time_quality
uptime_ms
```

Rekommenderat:

```text
raw_pulse_total
ignored_pulse_total
last_tip_at_epoch_s
boot_count eller boot_id
faults
```

### 6.2 Tip-event

Tip-event publiceras vid varje accepterad vippning.

Topic:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/tip
```

Tip-event ska inte vara retained. Det representerar en händelse i tiden, inte senaste läge.

Exempelpayload:

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
  "pulse_total": 123,
  "raw_pulse_total": 123,
  "ignored_pulse_total": 0,
  "uptime_ms": 12345678,
  "interval_ms": 35892,
  "gpio": "DI1",
  "time_valid": true,
  "epoch_s": 1782840000
}
```

Viktig princip:

```text
pulse_total är monotont räknande accepterade pulser och ska användas för att upptäcka luckor.
```

Mottagande system får inte enbart summera antalet mottagna tip-events utan att jämföra med `pulse_total`.

## 7. Retention och QoS

Rekommenderad MQTT-semantik:

| Meddelandetyp | Retained | Kommentar |
|---|---:|---|
| `state` | Ja | Senaste räknarställning och kanalstatus. |
| `tip` | Nej | Enskild händelse. Ska inte ersätta historik. |
| `status` | Ja | Online/offline via birth/will. |
| `heartbeat` | Valfritt, oftast ja | Senaste hälsoläge kan vara retained. |
| `diagnostics` | Valfritt | Beror på detaljeringsgrad. |

Retained state löser inte historik. Det sparar bara senaste state per topic. Därför ska `tip` inte användas som retained historik.

QoS kan användas för att förbättra leverans, men ska inte betraktas som hela datagarantin. För Nivå 1 är det fortfarande möjligt att exakt tidsfördelning går förlorad när mottagare eller broker är nere. För Nivå 2 krävs lokal journal och bekräftelse från backend.

## 8. Meddelandetyper

Framtida loggrar bör minst separera:

```text
state
tip
status
heartbeat
```

För Nivå 2 kan följande tillkomma:

```text
batch
acknowledgement
service_instruction
```

### Status

Loggerövergripande status:

```text
regnlogger/<site_id>/<logger_id>/status
```

Exempel:

```text
retained online/offline
```

### Heartbeat

Loggerövergripande heartbeat:

```text
regnlogger/<site_id>/<logger_id>/heartbeat
```

Heartbeat bör vara ett periodiskt JSON-meddelande med räknare, firmware, uptime, tidstatus och hälsodata.

Exempelpayload:

```json
{
  "schema": "rainlens.logger.heartbeat.v1",
  "site_id": "sannesholma",
  "logger_id": "nimbus",
  "status": "online",
  "uptime_ms": 12345678,
  "boot_count": 4,
  "time_valid": true,
  "channels": {
    "rain_1": {
      "pulse_total": 123,
      "last_tip_at_epoch_s": 1782840000
    }
  },
  "firmware": "rainlens-field-prototype-v1",
  "faults": []
}
```

## 9. Nivå 2-tillägg: batch och bekräftelse

Nivå 2 kräver lokal journal och möjlighet att skicka ikapp events.

Då kan loggern använda:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/batch
regnlogger/<site_id>/<logger_id>/<channel_id>/acknowledgement
```

`batch` skickas från logger till backend och innehåller flera events.

`acknowledgement` skickas från backend till logger och bekräftar att events är mottagna och persistenta.

Nivå 1 behöver inte implementera detta, men payloadfält bör inte utformas så att Nivå 2 blir svår att införa.

## 10. Namngivning i Home Assistant

Kort `logger_id` kan vara poetiskt eller internt, men Home Assistant-namn ska vara självbärande.

Exempel:

```text
logger_id: nimbus
ha_prefix: regnlogger_nimbus
display_name: Regnlogger Nimbus
```

Exempel på HA-entiteter:

```text
sensor.regnlogger_nimbus_status
sensor.regnlogger_nimbus_uptime
sensor.regnlogger_nimbus_wifi_signal
sensor.regnlogger_nimbus_rain_1_pulse_total
binary_sensor.regnlogger_nimbus_online
```

För PoE/Ethernet-loggers bör Wi-Fi-specifika entiteter ersättas eller kompletteras med nätverksdiagnostik som är relevant för den aktuella hårdvaran.

## 11. Ingest-mappning

Ingest-adaptern ska inte bara skriva payload rakt in i regntabell.

Den ska på sikt mappa:

```text
MQTT topic + site_id + logger_id + channel_id + sensor_id
→ observation_series
→ aktiv measurement_setup
→ event_observations / interval_observations / point_observations
```

AppDaemon är nuvarande ingest-adapter i Home Assistant-miljön. Det ska vara möjligt att ersätta den med en fristående RainLens ingest utan att ändra loggerkontraktet.

Tekniskt loggertest kan mappas till separat testtabell enligt ADR-0009.

För Nivå 1 ska ingest även kunna skapa kvalitetsflaggor när `pulse_total` visar att events saknas.

Exempel:

```text
Förra state: pulse_total = 1000
Nytt state:  pulse_total = 1018
Mottagna tip-events under perioden: 12
Differens: 6 saknade events
```

Då ska ackumulerad mängd kunna beräknas, men perioden ska flaggas som tidsosäker.

## 12. Databasprincip

Tip-meddelanden från tipping bucket skrivs som händelseobservationer:

```text
hydromet.event_observations
```

Tekniska loggertest kan skrivas till:

```text
hydromet.rain_logger_test_events
```

Moln-/API-regn per tidsintervall skrivs som intervallobservationer:

```text
hydromet.interval_observations
```

Status och heartbeat skrivs till systemhälsa:

```text
hydromet.system_health
hydromet.system_alerts
```

Perioder där ackumulerad mängd kan återhämtas men exakt tidsfördelning saknas ska kunna markeras med kvalitetsflagga i rådata- eller bearbetningslagret.
