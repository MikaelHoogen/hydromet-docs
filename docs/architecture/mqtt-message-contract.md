# MQTT-meddelanden och loggerkontrakt

Status: Målbild / delvis nuläge

## 1. Syfte

Loggerkontraktet ska göra det tydligt hur mätare, loggrar, MQTT, AppDaemon och databas hänger ihop.

Målet är att rådata ska kunna lagras robust, med spårbar källa och tillräcklig diagnostik.

## 2. Identiteter

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

## 3. Nuvarande logger_ha

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

Detta är historiskt nuläge och får fortsätta fungera. Ny produktionslogger ska följa den nya logger- och platscentrerade strukturen.

## 4. Ny topic-struktur

Ny målbild för topics:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/<message_type>
```

Exempel:

```text
regnlogger/sannesholma/nimbus/rain_1/tip
regnlogger/sannesholma/nimbus/rain_1/status
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
tip         = message_type
```

Mätaridentiteten ska ligga i payloaden, inte användas som topic-nivå som styr hela loggern.

## 5. Namngivning i Home Assistant

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

## 6. Tip-meddelande

Exempel på fält:

```text
site_id
logger_id
channel_id
sensor_id
sensor_type
event
mm
pulse_total
raw_pulse_total
ignored_pulse_total
uptime_ms
interval_ms
gpio
time_valid
epoch_s
```

Exempelpayload:

```json
{
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
  "time_valid": true,
  "epoch_s": 1782840000
}
```

Viktig princip:

```text
pulse_total är monotont räknande accepterade pulser och ska användas för att upptäcka luckor.
```

## 7. Meddelandetyper

Framtida loggrar bör separera:

```text
tip
status
heartbeat
```

Status:

```text
retained online/offline
```

Heartbeat:

```text
periodiskt JSON-meddelande med räknare, firmware, uptime, tidstatus och hälsodata
```

## 8. AppDaemon-mappning

AppDaemon ska inte bara skriva payload rakt in i regntabell.

Den ska på sikt mappa:

```text
MQTT topic + site_id + logger_id + channel_id + sensor_id
→ observation_series
→ aktiv measurement_setup
→ event_observations / interval_observations / point_observations
```

Tekniskt loggertest kan mappas till separat testtabell enligt ADR-0009.

## 9. Databasprincip

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
