# MQTT-meddelanden och loggerkontrakt

Status: Målbild / delvis nuläge

## 1. Syfte

Loggerkontraktet ska göra det tydligt hur mätare, loggrar, MQTT, AppDaemon och databas hänger ihop.

Målet är att rådata ska kunna lagras robust, med spårbar källa och tillräcklig diagnostik.

## 2. Nuvarande logger_ha

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

## 3. Tip-meddelande

Exempel på fält:

```text
source
sensor_id
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

Viktig princip:

```text
pulse_total är monotont räknande accepterade pulser och ska användas för att upptäcka luckor.
```

## 4. Framtida målbild

Framtida loggrar bör separera:

```text
tip
status
heartbeat
```

Föreslagna topics:

```text
regnlogger/<källa>/<logger>/tip
regnlogger/<källa>/<logger>/status
regnlogger/<källa>/<logger>/heartbeat
```

Status:

```text
retained online/offline
```

Heartbeat:

```text
periodiskt JSON-meddelande med räknare, firmware, uptime, tidstatus och hälsodata
```

## 5. AppDaemon-mappning

AppDaemon ska inte bara skriva payload rakt in i regntabell.

Den ska på sikt mappa:

```text
MQTT topic + sensor_id
→ observation_series
→ aktiv measurement_setup
→ event_observations / interval_observations / point_observations
```

## 6. Databasprincip

Tip-meddelanden från tipping bucket skrivs som händelseobservationer:

```text
hydromet.event_observations
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
