# Nivå 1-design för RainLens/Hydromet-regnlogger

Status: Praktisk målbild för robust fältpilot

Detta dokument beskriver loggerns beteende och ansvar på Nivå 1 för en tipping bucket-regnmätare i RainLens/Hydromet.

Nivå 1 betyder robust fältpilot. Det är bättre än en enkel testlogger, men inte samma sak som en skottsäker produktionslogger.

## 1. Dokumentets roll

Detta dokument är styrande för:

```text
lokal pulsräkning
filter och debounce
räknarpersistens
publiceringsbeteende
återhämtning via pulse_total
fel- och osäkerhetshantering
test före fältdrift
```

Detaljer som hör hemma på andra nivåer ska inte dupliceras här:

- [MQTT-meddelanden och loggerkontrakt](mqtt-message-contract.md) är styrande för topics, payloadfält, schema och retained-regler.
- [Hårdvaruförteckningen](../hardware/index.md) är styrande för fysiska ingångar och interna hårdvarubindningar.
- [Waveshare ESP32-S3 ETH 8DI 8RO](../hardware/waveshare-esp32-s3-eth-8di-8ro.md) är styrande för mappningen `DI1 → GPIO4` på den aktuella modellen.
- [Regnobservatoriet](../modules/rain-observatory.md) är styrande för den konkreta Nimbus-installationen.

## 2. Rekommenderad arkitektur

```text
Tipping bucket
→ physical_input på vald hårdvara
→ enhetsspecifik hardware_binding
→ ESPHome PoE/Ethernet-logger
→ lokal monoton pulse_total
→ MQTT retained channel state
→ MQTT live tip-events
→ utbytbar ingest-adapter
→ databas + kvalitetsflaggor
```

Grundprincip:

```text
Loggern räknar.
MQTT transporterar.
Ingest-adaptern jämför, tolkar och lagrar.
Home Assistant och andra klienter visar.
```

AppDaemon är nuvarande ingest-adapter i Home Assistant-miljön. Den är en implementation, inte ett krav i kärnarkitekturen.

MQTT-event ska inte vara den enda sanningen. För Nivå 1 är loggerns lokala `pulse_total` den bästa tillgängliga sanningen för ackumulerad pulsdata.

## 3. Nivå 1 och dess gräns

Nivå 1 har:

```text
lokal räknare
begränsad persistent lagring
retained state
live-events
periodisk heartbeat
gap-detektering hos mottagaren
synliga kvalitetsflaggor
```

Nivå 1 har inte:

```text
lokal händelsejournal med varje puls
backend-acknowledgement
replay av individuella events
fullständig transaktionsgaranti mellan logger och databas
```

Det senare hör till en framtida Nivå 2.

## 4. Designbeslut

| Område | Beslut |
|---|---|
| Primär räknare | Loggern äger `pulse_total`, inte AppDaemon. |
| MQTT state | Kanalens state är retained och publiceras vid varje accepterad vippning samt periodiskt. |
| MQTT tip-event | Publiceras vid varje accepterad vippning och är inte retained. |
| Status | Loggerns birth/will-status är retained. |
| Heartbeat | Publiceras periodiskt och beskriver loggerns och kanalernas hälsa. |
| Tid | `epoch_s` används bara när tiden är giltig. `uptime_ms` skickas alltid. |
| Debounce | Egen filterlogik med minsta tid mellan accepterade pulser. |
| Persistens | ESPHome `globals.restore_value` med rimligt `flash_write_interval`. |
| Mottagare | Ingest-adaptern jämför events och state mot `pulse_total`. |
| Begränsning | Exakt tidsfördelning kan gå förlorad vid avbrott, men osäkerheten ska flaggas. |

## 5. Från fysisk ingång till logisk kanal

Nivå 1-designen förutsätter att installationen först pekar ut en fysisk ingång på vald hårdvarumodell.

```text
channel_id
→ physical_input
→ uppslag i hårdvaruförteckningen
→ hardware_binding
→ firmwarekomponent som läser signalen
```

För Nimbus är detta:

```text
rain_1
→ DI1 / IN1
→ GPIO4 på Waveshare-modellen
→ ESPHome binary_sensor
```

`GPIO4` är inte en del av RainLens-kontraktet. Det är den aktuella hårdvarumodellens interna bindning för `DI1`.

På annan hårdvara kan samma `channel_id: rain_1` läsas via exempelvis en annan GPIO, en I/O-expander eller en Modbus-ingång.

## 6. ESPHome-strategi

Rekommenderat spår för Nimbus:

```text
resolved hardware input
→ binary_sensor
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

För Nivå 1 föredras en lokal firmwarekomponent med egen logik framför att låta Home Assistant eller AppDaemon vara första räknare.

Motivet är att loggern behöver kontroll över:

- lokal räknare
- debounce/filter
- MQTT-publicering
- tidstatus
- diagnostik
- state/event-separering

## 7. Räknare och debounce

Loggern ska skilja mellan:

```text
raw_pulse_total      = alla detekterade pulser
pulse_total          = accepterade pulser
ignored_pulse_total  = bortfiltrerade pulser
```

Rekommenderad startpunkt:

```text
debounce_ms = 250 ms
```

Vid `0.2 mm` per tip motsvarar 250 ms en teoretisk intensitet långt över realistiskt regn. Det ger god marginal mot kontaktstuds utan att filtrera bort rimliga regnhändelser.

Filtervärdet ska vara konfigurerbart och verifieras med den verkliga mätaren och ingångskretsen.

## 8. Persistens

Nivå 1 ska använda en lokal räknare som återställs efter reboot så långt ESPHome tillåter.

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

En lägre återläst räknare efter reboot ska inte döljas eller normaliseras bort. Mottagaren ska kunna flagga räknarregression eller osäker persistens.

## 9. MQTT-beteende

Det kanoniska MQTT-kontraktet finns i [MQTT-meddelanden och loggerkontrakt](mqtt-message-contract.md).

Nivå 1 använder:

```text
regnlogger/<site_id>/<logger_id>/status
regnlogger/<site_id>/<logger_id>/heartbeat
regnlogger/<site_id>/<logger_id>/<channel_id>/state
regnlogger/<site_id>/<logger_id>/<channel_id>/tip
```

För Nimbus:

```text
regnlogger/sannesholma/nimbus/status
regnlogger/sannesholma/nimbus/heartbeat
regnlogger/sannesholma/nimbus/rain_1/state
regnlogger/sannesholma/nimbus/rain_1/tip
```

Publiceringsregler:

```text
status    = retained birth/will online/offline
state     = retained, vid varje accepterad puls och periodiskt
tip       = inte retained, vid varje accepterad puls
heartbeat = periodiskt hälsomeddelande, normalt inte retained
```

Kanoniska scheman:

```text
rainlens.logger.channel_state.v1
rainlens.logger.tip_event.v1
rainlens.logger.heartbeat.v1
```

## 10. Tidshantering

Nivå 1 ska bära både relativ tid och tidstatus.

```text
uptime_ms skickas alltid.
epoch_s skickas bara när tid är giltig.
time_valid skickas alltid.
```

Vid boot utan giltig tid:

```text
time_valid = false
uptime_ms används som relativ markör
epoch_s utelämnas eller är null
```

När tid senare blir giltig:

```text
time_valid = true
nya events får epoch_s
```

Viktig regel:

```text
Loggern får inte publicera falsk UTC-tid som ser giltig ut.
```

## 11. Ingest och återhämtning

Ingest-adaptern ska inte bara summera inkomna `tip`-events.

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
4. Om pulse_total är oförändrad: behandla som möjlig dubblett.
5. Om pulse_total är lägre än senast kända: flagga counter_regression.
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

Ackumulerad mängd kan då återhämtas, men exakt tidsfördelning ska inte konstrueras i efterhand.

## 12. Kvalitetsflaggor och synlig osäkerhet

Nivå 1 ska minst kunna representera följande situationer i mottagande system:

```text
counter_gap
counter_regression
duplicate_event
time_invalid
time_distribution_uncertain
reboot_persistence_uncertain
heartbeat_missing
```

Exakta namn kan låsas i datamodellen, men semantiken får inte tappas bort.

## 13. Kända Nivå 1-begränsningar

Nivå 1 kan hantera:

- AppDaemon- eller ingestavbrott genom retained state och räknarhopp.
- Home Assistant-omstart genom retained state.
- Enstaka missade live-events genom `pulse_total`.

Nivå 1 kan bara upptäcka eller flagga:

- brokeravbrott medan det regnar
- logger-reboot före senaste persistenta skrivning
- start utan giltig tid
- strömavbrott exakt vid puls
- osäker tidsfördelning under avbrott

Detta är inte ett fel i Nivå 1, så länge osäkerheten är synlig och systemet inte hittar på precision som saknas.

## 14. Nimbus-installationen

Nimbus-installationen definieras i regnobservatoriets installationsdokumentation:

```yaml
site_id: sannesholma
logger_id: nimbus
hardware_model: waveshare_esp32_s3_eth_8di_8ro

channels:
  rain_1:
    physical_input: DI1
    sensor_id: tb4_0p2
    sensor_type: tipping_bucket
    mm_per_tip: 0.2
```

Hårdvaruförteckningen löser sedan:

```text
waveshare_esp32_s3_eth_8di_8ro + DI1
→ GPIO4
```

Firmware får använda den upplösta bindningen `GPIO4`, men installationskonfigurationen och MQTT-kontraktet ska fortsätta använda `physical_input: DI1` respektive `channel_id: rain_1`.

## 15. Testfall före fältdrift

Innan loggern betraktas som Nivå 1 ska följande testas:

| Test | Förväntat resultat |
|---|---|
| En fysisk vippning | `pulse_total` ökar med 1, state och tip publiceras. |
| Simulerad studs | `raw_pulse_total` kan öka, men `pulse_total` ska bara öka en gång. |
| Ingest nere under flera tips | Mängd återhämtas via state, tidsosäkerhet flaggas. |
| Home Assistant restart | Retained state återläses utan dubbelräkning. |
| Brokeravbrott | Loggern fortsätter räkna lokalt, state visar total efter återkomst. |
| Logger reboot | `boot_count` ökar och räknaren återställs eller avvikelse flaggas. |
| Boot utan tid | Payload har `time_valid=false`. |
| Tid blir giltig | Nya events får `time_valid=true`. |
| Dubblett-event | Mottagaren dubbelräknar inte. |
| Räknarhopp | Saknad mängd beräknas och tidsfördelningen flaggas som osäker. |
| Räknarregression | Avvikelsen flaggas och döljs inte. |
| Heartbeat saknas | Systemhälsa/larm kan reagera. |

## 16. Slutsats

Bästa Nivå 1 för RainLens/Hydromet är:

```text
ESPHome PoE/Ethernet
+ fysisk ingång upplöst via hårdvaruförteckning
+ lokal firmwarekomponent för pulsläsning
+ egen debounce/filterlogik
+ lokal persistent pulse_total
+ retained state vid varje accepterad vippning och periodiskt
+ non-retained tip-event vid varje accepterad vippning
+ heartbeat
+ ingestbaserad gap-detektering
+ kvalitetsflaggor för osäker tidsfördelning
```

Detta är en stark och ärlig fältpilot. Den är inte Nivå 2, men den undviker att systemet ser fungerande ut samtidigt som pulser försvinner utan synlig flagga.
