# Nivå 1-design för RainLens/Hydromet-regnlogger

Status: Praktisk målbild för robust fältpilot

Detta dokument beskriver den rekommenderade Nivå 1-implementationen för en tipping bucket-regnlogger i RainLens/Hydromet.

Nivå 1 betyder robust fältpilot. Det är bättre än en enkel testlogger, men inte samma sak som en skottsäker produktionslogger.

## 1. Rekommenderad arkitektur

```text
Tipping bucket
→ ESPHome PoE/Ethernet-logger
→ lokal monoton pulse_total
→ MQTT retained state
→ MQTT live tip-events
→ AppDaemon/Hydromet ingest
→ databas + kvalitetsflaggor
```

Grundprincip:

```text
Loggern räknar.
MQTT transporterar.
AppDaemon tolkar och lagrar.
Home Assistant visar.
```

MQTT-event ska inte vara den enda sanningen. För Nivå 1 är loggerns lokala `pulse_total` den bästa tillgängliga sanningen för ackumulerad pulsdata.

## 2. Designbeslut

| Område | Beslut |
|---|---|
| Primär räknare | Loggern äger `pulse_total`, inte AppDaemon. |
| MQTT state | Retained och publiceras vid varje accepterad vippning samt periodiskt. |
| MQTT tip-event | Publiceras vid varje accepterad vippning och är inte retained. |
| Tid | `epoch_s` används bara när tiden är giltig. `uptime_ms` skickas alltid. |
| Debounce | Egen filterlogik med minsta tid mellan accepterade pulser. |
| Persistens | ESPHome `globals.restore_value` med rimligt `flash_write_interval`. |
| Mottagare | AppDaemon jämför events mot `pulse_total`. |
| Begränsning | Exakt tidsfördelning kan gå förlorad vid avbrott, men ska flaggas. |

## 3. ESPHome-strategi

Rekommenderat spår:

```text
GPIO binary_sensor
→ on_press
→ raw_pulse_total ökar
→ debounce/filter
→ om godkänd puls:
   pulse_total ökar
   last_tip_uptime_ms uppdateras
   last_tip_epoch_s uppdateras om tid är giltig
   retained state publiceras
   live tip-event publiceras
```

För Nivå 1 föredras `binary_sensor` med egen lambda-logik framför att låta Home Assistant eller AppDaemon vara första räknare.

Motivet är att vi behöver kontroll över:

- lokal räknare
- debounce/filter
- MQTT-payload
- tidstatus
- diagnostik
- state/event-separering

## 4. Persistens

Nivå 1 ska använda lokal räknare som återställs efter reboot så långt ESPHome tillåter.

Rekommenderad princip:

```text
pulse_total lagras som ESPHome global med restore_value.
flash_write_interval sätts inte till 0s.
```

Exempel:

```yaml
preferences:
  flash_write_interval: 1min
```

Känd begränsning:

```text
Vid plötsligt strömavbrott kan pulser sedan senaste persistenta skrivning vara osäkra.
```

Detta är en Nivå 1-begränsning och ska kunna flaggas av mottagande system om räknaren beter sig oväntat efter reboot.

## 5. MQTT-topics

Rekommenderade topics:

```text
regnlogger/<site_id>/<logger_id>/status
regnlogger/<site_id>/<logger_id>/heartbeat
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

## 6. State-payload

`state` är senaste kända läge och ska vara retained.

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

- `site_id`
- `logger_id`
- `channel_id`
- `sensor_id`
- `mm_per_tip`
- `pulse_total`
- `rain_total_mm`
- `time_valid`
- `uptime_ms`

Rekommenderat:

- `raw_pulse_total`
- `ignored_pulse_total`
- `last_tip_epoch_s`
- `last_tip_uptime_ms`
- `boot_count`
- `firmware`
- `faults`

## 7. Tip-event-payload

`tip` är en enskild accepterad vippning och ska inte vara retained.

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

Om tid inte är giltig ska `time_valid` vara `false`. Då får `epoch_s` utelämnas eller sättas till `null`, beroende på vad implementationen klarar tydligast.

Viktig regel:

```text
Loggern får inte publicera falsk UTC-tid som ser giltig ut.
```

## 8. Heartbeat

Heartbeat bör publiceras periodiskt, till exempel var 30:e eller 60:e sekund.

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
  "channels": {
    "rain_1": {
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

## 9. Tidshantering

Nivå 1 ska bära både relativ tid och tidstatus.

Princip:

```text
uptime_ms skickas alltid.
epoch_s skickas bara när tid är giltig.
time_valid skickas alltid.
```

Vid boot utan giltig tid:

```text
time_valid = false
uptime_ms används som relativ markör
```

När tid senare blir giltig:

```text
time_valid = true
nya events får epoch_s
```

## 10. Debounce/filter

Nivå 1 ska ha en dokumenterad filterstrategi.

Rekommenderad startpunkt:

```text
debounce_ms = 250 ms
```

Motiv:

```text
Vid 0,2 mm per tip motsvarar 250 ms en teoretiskt extrem intensitet långt över realistiskt regn.
Det ger god marginal mot kontaktstuds utan att filtrera bort rimliga regnhändelser.
```

Loggern bör skilja mellan:

```text
raw_pulse_total      = alla detekterade pulser
pulse_total          = accepterade pulser
ignored_pulse_total  = bortfiltrerade pulser
```

## 11. AppDaemon/ingest-strategi

AppDaemon ska inte bara summera inkomna `tip`-events.

Den ska hålla per kanal:

```text
last_seen_pulse_total
last_state_pulse_total
last_good_event_time
last_state_time
```

Vid `tip`-event:

```text
1. Läs pulse_total.
2. Om pulse_total är ett steg större än senast kända: normal händelse.
3. Om pulse_total hoppar mer än ett steg: skriv händelsen och flagga lucka.
4. Om pulse_total är lägre än senast kända: flagga counter_regression.
```

Vid `state`:

```text
1. Läs pulse_total.
2. Jämför mot senast kända pulse_total.
3. Om state visar fler pulser än mottagna events: beräkna saknad ackumulerad mängd.
4. Flagga perioden som tidsosäker.
```

Exempel:

```text
Förra kända pulse_total = 1000
Nytt state pulse_total = 1018
Mottagna live-events = 12
Saknade events = 6
Saknad mängd = 6 × mm_per_tip
```

Då kan ackumulerad mängd återhämtas, men exakt tidsfördelning ska inte konstrueras i efterhand.

## 12. Kända Nivå 1-begränsningar

Nivå 1 kan hantera:

- AppDaemon-avbrott genom retained state och räknarhopp.
- Home Assistant-omstart genom retained state.
- Enstaka missade live-events genom `pulse_total`.

Nivå 1 kan bara flagga:

- brokeravbrott medan det regnar
- logger-reboot före senaste persistenta skrivning
- start utan giltig tid
- strömavbrott exakt vid puls
- osäker tidsfördelning under avbrott

Detta är inte fel i Nivå 1, så länge osäkerheten syns.

## 13. Testfall före fältdrift

Innan loggern betraktas som Nivå 1 ska följande testas:

| Test | Förväntat resultat |
|---|---|
| En fysisk vippning | `pulse_total` ökar med 1, state och tip publiceras. |
| Simulerad studs | `raw_pulse_total` kan öka, men `pulse_total` ska bara öka en gång. |
| AppDaemon nere under flera tips | Mängd återhämtas via state, tidsosäkerhet flaggas. |
| Home Assistant restart | Retained state återläses utan dubbelräkning. |
| Brokeravbrott | Loggern fortsätter räkna lokalt, state visar total efter återkomst. |
| Logger reboot | `boot_count` ökar och räknaren återställs eller avvikelse flaggas. |
| Boot utan tid | Payload har `time_valid=false`. |
| Tid blir giltig | Nya events får `time_valid=true`. |
| Dubblett-event | Mottagaren dubbelräknar inte. |
| Heartbeat saknas | Systemhälsa/larm kan reagera. |

## 14. Slutsats

Bästa Nivå 1 för RainLens/Hydromet är:

```text
ESPHome PoE/Ethernet
+ GPIO binary_sensor
+ egen debounce/filterlogik
+ lokal persistent pulse_total
+ retained state vid varje accepterad vippning
+ non-retained tip-event vid varje accepterad vippning
+ heartbeat
+ AppDaemon gap-detektering
+ kvalitetsflaggor för osäker tidsfördelning
```

Detta är en stark och ärlig fältpilot. Den är inte Nivå 2, men den undviker att systemet ser fungerande ut samtidigt som pulser försvinner utan synlig flagga.
