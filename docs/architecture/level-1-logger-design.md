# Nivå 1-design för RainLens/Hydromet-regnlogger

Status: Praktisk målbild för robust fältpilot

Detta dokument beskriver loggerns beteende och ansvar på Nivå 1 för en tipping bucket-regnmätare i RainLens/Hydromet.

Nivå 1 betyder robust fältpilot. Det är bättre än en enkel testlogger, men inte samma sak som en skottsäker produktionslogger.

## 1. Dokumentets roll

Detta dokument är styrande för:

```text
lokal pulsräkning
fysisk ingångs robusthetskrav
filter och debounce
räknarpersistens
publiceringsbeteende
återhämtning via pulse_total
fel- och osäkerhetshantering
test före fältdrift
```

Detaljer som hör hemma på andra nivåer ska inte dupliceras här:

- [MQTT-meddelanden och loggerkontrakt](mqtt-message-contract.md) är styrande för topics, payloadfält, schema och retained-regler.
- [Hårdvaruförteckningen](../hardware/index.md) är styrande för fysiska ingångar, fältretur och interna hårdvarubindningar.
- [Waveshare ESP32-S3-POE-ETH-8DI-8DO](../hardware/waveshare-esp32-s3-poe-eth-8di-8do.md) är styrande för `DI1–DGND`, `DI1 → GPIO4`, polaritet och målkonfiguration på den aktuella modellen.
- [Sännesholma Nimbus](../installations/sannesholma-nimbus.md) är styrande för den konkreta installationen och konfigurationskällorna.
- [Verifiering av Nimbus DI1-ingång](../runbooks/nimbus-di1-verification.md) är styrande för bänktest och acceptans.
- [Regnobservatoriet](../modules/rain-observatory.md) beskriver hur observationerna används i regndomänen.

## 2. Rekommenderad arkitektur

```text
Tipping bucket
→ physical_input + field_return på vald hårdvara
→ enhetsspecifik hardware_binding med definierad vilonivå
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
dokumenterad och verifierad fysisk ingång
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
| Fysisk ingång | Fältkoppling, retur, aktiv nivå och vilonivå ska vara dokumenterade och bänkverifierade. |
| GPIO-vilonivå | En digital ingång får inte tas i drift flytande eller med okänd pull-konfiguration. |
| Primär räknare | Loggern äger `pulse_total`, inte AppDaemon. |
| MQTT state | Kanalens state är retained och publiceras vid varje accepterad vippning samt periodiskt. |
| MQTT tip-event | Publiceras vid varje accepterad vippning och är inte retained. |
| Status | Loggerns birth/will-status är retained. |
| Heartbeat | Publiceras periodiskt och beskriver loggerns och kanalernas hälsa. |
| Tid | `epoch_s` används bara när tiden är giltig. `uptime_ms` skickas alltid. |
| Debounce | Egen filterlogik med minsta tid mellan accepterade pulser. |
| Persistens | ESPHome `globals.restore_value` med rimligt `flash_write_interval`. |
| Mottagare | Ingest-adaptern jämför events och state mot `pulse_total`. |
| HA-diagnostik | Får läsa och visa loggerns lokala värden, men får inte vara en del av pulsräkning, återhämtning eller MQTT-kontrakt. |
| Begränsning | Exakt tidsfördelning kan gå förlorad vid avbrott, men osäkerheten ska flaggas. |

## 5. Från fysisk ingång till logisk kanal

Nivå 1-designen förutsätter att installationen först pekar ut både fysisk ingång och avsedd fältretur på vald hårdvarumodell.

```text
channel_id
→ physical_input
→ field_return
→ uppslag i hårdvaruförteckningen
→ hardware_binding
→ firmwarekomponent som läser signalen
```

För Nimbus är detta:

```text
rain_1
→ KISTERS TB4 potentialfri kontakt
→ DI1 / IN1 och DGND
→ isolerad Waveshare-ingång
→ GPIO4 på ESP32-sidan
→ ESPHome binary_sensor
```

`GPIO4` är inte en del av RainLens-kontraktet. Det är den aktuella hårdvarumodellens interna bindning för `DI1`.

På annan hårdvara kan samma `channel_id: rain_1` läsas via exempelvis en annan GPIO, en I/O-expander eller en Modbus-ingång.

### Generell robusthetsregel

Varje fysisk digital ingång ska dokumentera:

```text
vilka plintar som sluter fältslingan
om extern matning krävs
normal vilonivå
aktiv elektrisk nivå
pull-up eller pull-down
inversion
vilken flank som räknas
```

En fri ledning som berörs med fingret är inte ett giltigt funktionstest. Den kan fungera som antenn och koppla in störning kapacitivt.

### Nimbus målkonfiguration

```yaml
pin:
  number: GPIO4
  mode:
    input: true
    pullup: true
  inverted: true
```

Pull-up ligger på GPIO-sidan efter optokopplaren. Den matar inte TB4 och ersätter inte kopplingen mellan `DI1` och `DGND`.

Ett komplett offentligt komponentnivåschema för Waveshare-kortet har inte påträffats. Därför ska den elektriska funktionen verifieras praktiskt och inte enbart härledas från antagna komponentvärden.

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

- fysisk ingång och flank,
- lokal räknare,
- debounce/filter,
- MQTT-publicering,
- tidstatus,
- diagnostik,
- state/event-separering.

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

Debounce löser inte en elektriskt flytande GPIO. Definierad vilonivå och debounce är separata krav.

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
physical_input_unverified
input_idle_unstable
```

Exakta namn kan låsas i datamodellen, men semantiken får inte tappas bort.

## 13. Kända Nivå 1-begränsningar

Nivå 1 kan hantera:

- AppDaemon- eller ingestavbrott genom retained state och räknarhopp.
- Home Assistant-omstart genom retained state.
- Enstaka missade live-events genom `pulse_total`.

Nivå 1 kan bara upptäcka eller flagga:

- brokeravbrott medan det regnar,
- logger-reboot före senaste persistenta skrivning,
- start utan giltig tid,
- strömavbrott exakt vid puls,
- osäker tidsfördelning under avbrott.

Detta är inte ett fel i Nivå 1, så länge osäkerheten är synlig och systemet inte hittar på precision som saknas.

## 14. Nimbus-installationen

Nimbus-installationen definieras i [Sännesholma Nimbus](../installations/sannesholma-nimbus.md):

```yaml
site_id: sannesholma
logger_id: nimbus
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do

channels:
  rain_1:
    physical_input: DI1
    field_return: DGND
    sensor_id: tb4_0p2
    sensor_type: tipping_bucket
    mm_per_tip: 0.2
```

Hårdvaruförteckningen löser sedan:

```text
waveshare_esp32_s3_poe_eth_8di_8do + DI1 + DGND
→ isolerad passiv kontaktkrets
→ GPIO4
```

Firmware får använda den upplösta bindningen `GPIO4`, men installationskonfigurationen och MQTT-kontraktet ska fortsätta använda `physical_input: DI1` respektive `channel_id: rain_1`.

Aktiv driftkonfiguration och referensimplementation ska hållas isär:

```text
Aktiv:
MikaelHoogen/home-assistant/esphome/regnlogger-nimbus.yaml

Referens:
MikaelHoogen/hydromet-core/deployments/sannesholma/nimbus/esphome.yaml
```

## 15. Home Assistant-diagnostik

Nimbus och andra Nivå 1-loggrar får exponera lokal drift- och testdiagnostik till Home Assistant genom ESPHome Native API.

Den kritiska Nivå 1-kedjan är:

```text
fysisk ingång
→ lokal filter- och debounce-logik
→ lokala räknare
→ persistens
→ MQTT state och events
```

Diagnostiklagret är separat:

```text
befintliga lokala värden
→ skrivskyddade ESPHome-entiteter
→ Native API
→ Home Assistant
```

Diagnostiken får inte bli ett beroende för loggerfunktionen. Loggern ska fortsätta läsa ingången, räkna, lagra och publicera enligt MQTT-kontraktet även när Home Assistant eller Native API är otillgängligt.

Designregler:

- Home Assistant får inte äga, återställa, korrigera eller räkna `pulse_total`.
- Diagnostikentiteter får bara läsa redan befintliga lokala värden och tillstånd.
- Den firmwarekomponent som läser den fysiska ingången och räknar pulser ska inte ersättas av en HA-entitet.
- Den fysiska ingången får vara intern i ESPHome och speglas till en separat skrivskyddad diagnostikentitet.
- `api.reboot_timeout` ska vara `0s`, så att utebliven HA/API-anslutning inte startar om loggern.
- Diagnostikens uppdateringsintervall ska vara måttligt och får inte skapa onödig last.
- Diagnostikentiteter ska normalt märkas med `entity_category: diagnostic`.
- HA-diagnostiken är inte en observationskälla, inte en del av MQTT-kontraktet och inte grund för databasens återhämtning.

Rekommenderad minsta diagnostik för inkörning och drift:

```text
logger online
fysisk ingångs aktuella tillstånd
pulse_total
raw_pulse_total
ignored_pulse_total
boot_count
uptime
time_valid
MQTT ansluten
senaste accepterade puls
intervall mellan de senaste accepterade pulserna
```

Diagnostiken stärker verifierbarheten i Nivå 1, men den förändrar inte ansvarsfördelningen:

```text
Loggern räknar och publicerar.
Home Assistant visar.
```

## 16. Testfall före fältdrift

Innan loggern betraktas som Nivå 1 ska följande testas:

| Test | Förväntat resultat |
|---|---|
| Öppen fysisk ingång utan fältkabel | Stabil `OFF`, inga spontana pulser. |
| Kontrollerad bygel mellan rätt plintar | Exakt en accepterad puls när kontakten sluts. |
| Bygel tas bort | Ingången återgår till `OFF` utan extra regnpuls. |
| Lös ledning berörs med finger | Betraktas inte som funktionsbevis; inga accepterade pulser i robust målkonfiguration. |
| En fysisk vippning | `pulse_total` ökar med 1, state och tip publiceras. |
| Tio vippningar | Exakt tio accepterade pulser. |
| Hundra vippningar vid 0,2 mm/tip | Exakt 100 pulser och 20,0 mm. |
| Simulerad studs | `raw_pulse_total` kan öka, men `pulse_total` ska bara öka en gång. |
| Ingest nere under flera tips | Mängd återhämtas via state, tidsosäkerhet flaggas. |
| Home Assistant restart | Retained state återläses utan dubbelräkning. |
| Home Assistant/API frånkopplat | Loggern fortsätter läsa, räkna, lagra och publicera utan omstart. |
| Brokeravbrott | Loggern fortsätter räkna lokalt, state visar total efter återkomst. |
| Logger reboot | `boot_count` ökar och räknaren återställs eller avvikelse flaggas. |
| Boot utan tid | Payload har `time_valid=false`. |
| Tid blir giltig | Nya events får `time_valid=true`. |
| Dubblett-event | Mottagaren dubbelräknar inte. |
| Räknarhopp | Saknad mängd beräknas och tidsfördelningen flaggas som osäker. |
| Räknarregression | Avvikelsen flaggas och döljs inte. |
| Heartbeat saknas | Systemhälsa/larm kan reagera. |

Den enhetsspecifika proceduren finns i [Verifiering av Nimbus DI1-ingång](../runbooks/nimbus-di1-verification.md).

## 17. Slutsats

Bästa Nivå 1 för RainLens/Hydromet är:

```text
ESPHome PoE/Ethernet
+ dokumenterad och verifierad fysisk ingång
+ definierad elektrisk vilonivå
+ fysisk ingång upplöst via hårdvaruförteckning
+ lokal firmwarekomponent för pulsläsning
+ egen debounce/filterlogik
+ lokal persistent pulse_total
+ retained state vid varje accepterad vippning och periodiskt
+ non-retained tip-event vid varje accepterad vippning
+ heartbeat
+ skrivskyddad och icke-kritisk HA-diagnostik
+ ingestbaserad gap-detektering
+ kvalitetsflaggor för osäker tidsfördelning
```

Detta är en stark och ärlig fältpilot. Den är inte Nivå 2, men den undviker att systemet ser fungerande ut samtidigt som pulser försvinner eller ingången är elektriskt odefinierad utan synlig flagga.
