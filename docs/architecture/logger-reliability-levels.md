# Loggernivåer och mätintegritet

Status: Arkitekturprincip / målbild för RainLens/Hydromet

## 1. Syfte

Detta dokument beskriver hur RainLens/Hydromet skiljer mellan olika nivåer av regnloggers: från enkel testlogger till mätarklassad logger.

Syftet är att undvika att en prototyp av misstag betraktas som produktionssäker. En logger kan fungera bra i Home Assistant och ändå sakna de garantier som krävs för långsiktig nederbördsstatistik, blockregn, IDF-analys och återkomsttidsbedömning.

Dokumentet är särskilt viktigt för den nuvarande loggerlinjen med:

```text
ESPHome → MQTT → Home Assistant/AppDaemon → Hydromet/RainLens
```

Den lösningen kan vara en robust fältpilot, men den är inte automatiskt en skottsäker produktionslogger.

## 2. Grundprincip

RainLens/Hydromet ska skilja mellan prototypnivå och produktionsnivå för regnloggers.

Den nuvarande ESPHome + MQTT + Home Assistant/AppDaemon-baserade loggern ska betraktas som en robust fältpilot, inte som en skottsäker produktionslogger.

Målet för denna nivå är att säkerställa ackumulerad nederbörd genom lokal räknarställning och retained state, samt att få tidsupplösta tip-events när mottagande system är tillgängliga.

Loggern ska inte vara en dum pulssändare. Varje vippning ska först påverka loggerns lokala monotona `tip_count` eller `pulse_total`. MQTT används därefter för att publicera retained state och live-events. Backend/AppDaemon ska kunna upptäcka hopp i räknarställning och flagga perioder där exakt tidsfördelning inte kan garanteras.

MQTT, Home Assistant och AppDaemon ska inte betraktas som primär sanning för rå pulsräkning. De är transport- och konsumentlager.

```text
Fel modell:
GPIO-puls → MQTT-event → AppDaemon räknar

Rätt modell:
GPIO-puls → lokal logger-räknare → MQTT state/event → ingest/backend
```

## 3. Begrepp

| Begrepp | Betydelse |
|---|---|
| `tip_count` / `pulse_total` | Monotont ökande räknare för accepterade vippningar. |
| `raw_pulse_total` | Räknare för råa pulser före filtrering/debounce, om tillgänglig. |
| `ignored_pulse_total` | Räknare för pulser som filtrerats bort som studs/störning, om tillgänglig. |
| `state` | Senaste kända tillstånd för kanal/logger. Bör publiceras retained. |
| `event` | En enskild tidsstämplad vippning. Bör inte vara retained. |
| `journal` | Lokal buffert/logg av events som ännu inte säkert sparats i backend. |
| `ack` | Bekräftelse från backend att events är mottagna och persistenta. |
| `time_quality` | Flagga som anger om tidsstämpeln är säker, rekonstruerad eller osynkad. |

## 4. Loggernivåer

### Nivå 0 – Enkel testlogger

Syfte: hårdvarutest, proof-of-concept och snabb verifiering av signalväg.

Typisk arkitektur:

```text
ESPHome → MQTT/HA → AppDaemon/Home Assistant
```

Egenskaper:

- ESPHome räknar eller skickar pulser.
- Home Assistant eller AppDaemon tar emot.
- Ingen stark garanti för missade pulser.
- Ingen tydlig återhämtning av tidsserie efter mottagaravbrott.
- Ingen lokal eventjournal.

Begränsning:

```text
En puls kan i praktiken bara existera som ett flyktigt MQTT-event.
```

Denna nivå ska inte användas som grund för långsiktig mätserie utan tydlig kvalitetsmarkering.

### Nivå 1 – Robust prototyp / fältpilot

Syfte: verklig fältdrift och lärande, men med ärligt redovisade begränsningar.

Detta är målnivån för nuvarande HA/AppDaemon/ESPHome-spår.

Krav:

- Loggern håller lokal monoton `tip_count` eller `pulse_total`.
- Räknaren publiceras som retained MQTT state.
- Varje accepterad vippning publiceras även som live-event med timestamp när tid finns.
- AppDaemon/backend jämför mottagna events mot räknarställning.
- Hopp i räknarställning används för att upptäcka missade events.
- Ackumulerad nederbörd kan återhämtas efter att AppDaemon/backend varit nere.
- Perioder där exakt tidsfördelning saknas ska flaggas som osäkra.
- Loggern publicerar status och diagnostik.

Exempel:

```text
12:00 mottagaren ser tip_count = 1000
12:10 mottagaren ligger nere
12:40 mottagaren ser tip_count = 1018
```

Då kan systemet återhämta ackumulerad mängd:

```text
18 tips × 0,2 mm = 3,6 mm
```

Men systemet vet inte exakt hur de 18 tipsen fördelades i tiden. Den perioden ska därför flaggas som osäker för intensitetsanalys.

Begränsning:

```text
Ackumulerad nederbörd kan räddas, men exakt puls-tidsserie kan gå förlorad vid broker-, backend- eller mottagaravbrott.
```

Nivå 1 är inte skottsäker produktion, men den är väsentligt bättre än en enkel pulspublisher.

### Nivå 2 – Produktionslogger

Syfte: produktionsnära logger där ingen dataförlust ska kunna ske tyst.

Krav:

- Loggern har lokal eventbuffer eller journal.
- Varje event får sekvensnummer.
- Backend ackar mottagna och persistenta events.
- Loggern kan skicka ikapp missade events efter avbrott.
- MQTT är endast transport.
- Loggern raderar inte lokala events förrän backend har ackat.
- Buffer overflow, journalfel, reboot och tidsosäkerhet blir explicita kvalitetsflaggor.

Möjlig implementation:

```text
ESPHome som plattform
+ egen ESPHome external component
+ lokal journal/outbox
+ ack-hantering
```

Alternativ:

```text
Egen firmware
+ lokal journal
+ MQTT batch/replay
```

Nivå 2 kräver mer än vanlig YAML-automation.

### Nivå 3 – Mätarklassad / industriell logger

Syfte: långsiktig drift med hög mätintegritet och dokumenterad felmodell.

Möjliga krav:

- Förstärkt hårdvara och signalväg.
- Extern FRAM, industriell pulsräknare eller motsvarande icke-flyktig lagring.
- Brownout-säkrad commit-strategi.
- Watchdog och självtest.
- Dokumenterad testprocedur.
- Tydlig service- och kalibreringsstrategi.
- Eventuell redundans i lagring, ström eller kommunikation.

Nivå 3 är inte mål för första RainLens-fältpiloten, men nivåmodellen ska inte hindra att systemet växer dit.

## 5. Nivå 1 som nuvarande mål

Nuvarande PoE/Ethernet-baserade ESPHome-logger ska i första hand byggas som Nivå 1.

Det innebär:

```text
ESPHome logger
→ lokal tip_count/pulse_total
→ retained MQTT state
→ live tip-events
→ AppDaemon/Hydromet ingest
→ delta-detektering och osäkerhetsflaggor
```

Den ska inte beskrivas som produktionslogger utan reservation. Bättre namn är:

```text
RainLens Field Prototype Logger v1
```

eller:

```text
Hydromet fältpilotlogger nivå 1
```

## 6. Konsekvenser för MQTT-kontraktet

MQTT-kontraktet ska separera state och events.

### State

State beskriver senaste kända läge och ska kunna användas för återhämtning.

Exempel:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/state
```

Egenskaper:

- retained
- innehåller `tip_count` / `pulse_total`
- innehåller `rain_total_mm`
- innehåller `last_tip_at` om tid finns
- innehåller `time_valid` eller `time_quality`
- innehåller reboot-/boot-information om möjligt

### Event

Event beskriver en enskild vippning.

Exempel:

```text
regnlogger/<site_id>/<logger_id>/<channel_id>/tip
```

Egenskaper:

- inte retained
- innehåller aktuell `tip_count` / `pulse_total`
- innehåller mm per tip
- innehåller timestamp när sådan finns
- används för realtidsintensitet och tidsserie

### Diagnostik

Loggern ska också publicera hälsodata.

Exempel:

```text
regnlogger/<site_id>/<logger_id>/status
regnlogger/<site_id>/<logger_id>/heartbeat
```

Diagnostik bör minst innehålla:

- online/offline
- uptime
- boot count eller boot id
- tidstatus
- aktuell räknarställning
- senaste accepterade puls
- eventuellt råa/ignorerade pulser
- firmwareversion

## 7. Kända begränsningar i Nivå 1

Nivå 1 är en fältpilotnivå. Följande begränsningar är accepterade om de dokumenteras och flaggas:

- Exakt puls-tidsserie kan förloras om MQTT-broker eller mottagare är nere.
- Retained state sparar senaste räknarställning, inte alla events.
- ESPHome-persistens till flash är inte samma sak som en per-puls journal.
- Vid strömavbrott kan pulser sedan senaste persistenta skrivning vara osäkra beroende på implementation.
- Home Assistant/AppDaemon ska inte ensam räknas som varaktig rådatakälla.

Viktig princip:

```text
Osäker data är acceptabel om den flaggas.
Tyst dataförlust är inte acceptabel.
```

## 8. Vägen mot Nivå 2

För att gå från Nivå 1 till Nivå 2 behöver loggern få lokal eventjournal eller buffert.

Nya komponenter:

- sekvensnummer per event
- lokal journal/outbox
- batch/replay av missade events
- ack från backend
- idempotent backend-ingest
- kvalitetsflaggor för journalfel, overflow och osynkad tid

Möjliga tekniska vägar:

1. ESPHome external component.
2. Egen firmware för ESP32/RP2040.
3. Extern FRAM eller annan icke-flyktig lagring.
4. Industriell pulsräknare framför loggern.

Det viktiga är att Nivå 1 redan använder fält som inte blockerar Nivå 2:

```text
site_id
logger_id
channel_id
sensor_id
tip_count / pulse_total
time_valid / time_quality
boot_id / boot_count
```

## 9. Praktisk regel för kommande YAML

ESPHome-YAML för Nivå 1 ska inte byggas som en ren pulspublisher.

Minimikrav:

```text
1. Lokal monoton räknare för accepterade pulser.
2. Retained state med räknarställning.
3. Live-event vid varje accepterad puls.
4. Status/heartbeat.
5. Tidsstatus i payload.
6. Diagnostik som gör tyst fel svårare.
7. AppDaemon/backend ska jämföra räknarhopp och flagga osäker period.
```

Exempel på oönskad design:

```text
binary_sensor.on_press → mqtt.publish("tip")
```

Exempel på önskad Nivå 1-design:

```text
binary_sensor.on_press
→ filtrera/debounce
→ öka lokal pulse_total
→ uppdatera retained state
→ publicera tip-event
→ heartbeat/diagnostik visar aktuell räknarställning
```

## 10. Sammanfattning

RainLens/Hydromet ska inte blanda ihop en fungerande logger med en produktionssäker logger.

Den nuvarande ESPHome + MQTT + Home Assistant/AppDaemon-lösningen ska byggas som en robust fältpilot på Nivå 1. Den ska ha lokal räknare, retained state, live-events och delta-detektering.

För riktig produktionslogger krävs Nivå 2: lokal eventjournal, sekvensnummer, backend-ack och replay.

Den viktigaste arkitekturprincipen är:

```text
En vippning får aldrig bara existera som ett flyktigt MQTT-event.
```
