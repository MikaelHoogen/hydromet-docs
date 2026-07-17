# Sännesholma Nimbus

Status: Aktiv installation / elektrisk ingångskoppling under verifiering

## 1. Syfte

Detta dokument beskriver den konkreta Nimbus-installationen i Sännesholma och skiljer mellan:

```text
aktiv driftkonfiguration
referensimplementation
normativ hårdvaru- och målkonfiguration
```

Det är viktigt att dessa tre nivåer inte blandas ihop.

## 2. Installationens identiteter

```yaml
site_id: sannesholma
logger_id: nimbus
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do
reliability_level: 1
network: poe_ethernet

channels:
  rain_1:
    physical_input: DI1
    field_return: DGND
    sensor_id: tb4_0p2
    sensor_manufacturer: KISTERS
    sensor_model: TB4
    sensor_type: tipping_bucket
    mm_per_tip: 0.2
```

## 3. Källor för konfiguration och dokumentation

### Aktiv driftkonfiguration

Den faktiska ESPHome-konfigurationen finns i Home Assistant-repot:

```text
MikaelHoogen/home-assistant
└── esphome/regnlogger-nimbus.yaml
```

Länk:

<https://github.com/MikaelHoogen/home-assistant/blob/master/esphome/regnlogger-nimbus.yaml>

Denna fil är källan för vad loggern faktiskt är avsedd att köra i Home Assistant-/ESPHome-miljön.

### Referensimplementation

Hydromet-core innehåller en separat referens-/utvecklingsfil:

```text
MikaelHoogen/hydromet-core
└── deployments/sannesholma/nimbus/esphome.yaml
```

Den filen får inte automatiskt behandlas som driftsatt firmware. Den visar en möjlig Nivå 1-implementation och ska hållas synkron med målarkitekturen, men aktiv drift avgörs av Home Assistant-repots `regnlogger-nimbus.yaml`.

### Normativ dokumentation

Fysiska terminaler, intern bindning och målkonfiguration definieras i:

- [Waveshare ESP32-S3-POE-ETH-8DI-8DO](../hardware/waveshare-esp32-s3-poe-eth-8di-8do.md)
- [Verifiering av Nimbus DI1-ingång](../runbooks/nimbus-di1-verification.md)
- [Nivå 1-design för regnlogger](../architecture/level-1-logger-design.md)

## 4. Fysisk inkoppling

KISTERS TB4:s potentialfria reedkontakt ska anslutas så här:

```text
TB4 ledare 1 ───────── DI1
TB4 ledare 2 ───────── DGND

DICOM/COM              oansluten
ESP32-GND              oansluten
extern ingångsmatning  ingen
```

TB4 ska alltså inte kopplas mellan `DI1` och `DICOM/COM`.

Kortet har intern isolerad terminalmatning för passiva kontakter. Den potentialfria TB4-kontakten sluter den isolerade fältslingan mellan `DI1` och `DGND`.

## 5. Firmwarebindning

```text
rain_1
→ DI1 / IN1
→ GPIO4
→ ESPHome binary_sensor
→ lokal debounce och pulsräkning
```

Målkonfigurationen för pinnen är:

```yaml
pin:
  number: GPIO4
  mode:
    input: true
    pullup: true
  inverted: true
```

Pull-up ligger på GPIO-sidan efter optokopplaren. Den matar inte TB4 och ersätter inte `DGND`.

## 6. Verifierat aktuellt driftläge 2026-07-17

Vid granskningen 2026-07-17 innehöll den aktiva filen `esphome/regnlogger-nimbus.yaml`:

```yaml
pin:
  number: GPIO4
  mode:
    input: true
  inverted: ${input_inverted}
```

Filen hade alltså:

- rätt exakta Waveshare-modell,
- `DI1 → GPIO4`,
- ESP-IDF,
- aktiv låg genom inversion,
- egen debounce på 250 ms,
- ingen explicit pull-up.

Detta dokumentationspaket ändrar inte den aktiva firmwarefilen. Följande avvikelse kvarstår tills en separat firmwareändring görs och verifieras:

```text
Dokumenterad målkonfiguration: input + pullup + inverted
Aktiv granskad konfiguration:  input + inverted
```

## 7. Varför pull-up ingår i målkonfigurationen

Optokopplarutgången förväntas dra GPIO4 låg när ingången är aktiv. När den är inaktiv måste GPIO4 ha en definierad hög vilonivå.

Intern pull-up väljs som robusthetsregel för att:

- undvika flytande eller störkänslig GPIO,
- minska falska flankhändelser,
- göra öppen kontakt entydigt `OFF`,
- få sluten kontakt att ge en reproducerbar aktiv låg flank.

Ett fullständigt officiellt kortschema har inte påträffats. Därför ska både polaritet och funktion verifieras praktiskt enligt runbooken.

## 8. Observerat fel- och testbeteende

Under bänktest har följande observerats:

- TB4 gav ingen reaktion i den tidigare kopplingen.
- En lös tråd på ingångssidan kunde ge många pulser.
- Beröring med finger kunde utlösa pulser.
- En ledning i `COM` med fri ände gav missvisande pulsbeteende.

En fri ledning och ett finger är inte ett giltigt funktionstest. Ledningen fungerar som antenn och kroppen kan koppla in störning kapacitivt.

Det kontrollerade grundtestet är i stället:

```text
kort bygel DI1–DGND
```

## 9. Acceptanskriterier före fältdrift

Nimbus ingångskanal är inte elektriskt godkänd förrän följande har verifierats:

1. Ingen ansluten fältledning ger stabilt `OFF` och noll pulser.
2. En kort bygel `DI1–DGND` ger exakt en `on_press` när den sätts dit.
3. Borttagning av bygeln ger `OFF` utan en extra regnpuls.
4. Tio manuella TB4-vippningar ger exakt tio accepterade pulser.
5. Hundra vippningar ger exakt 100 pulser och 20,0 mm.
6. Ingen spontan puls registreras under ett längre stilleståndstest.
7. Testresultatet dokumenteras med firmwareversion och Git-commit.

Den fullständiga proceduren finns i [Verifiering av Nimbus DI1-ingång](../runbooks/nimbus-di1-verification.md).

## 10. Spårbarhet för driftsatt firmware

Varje driftsättning bör dokumentera:

```yaml
deployed_at: YYYY-MM-DD
active_repository: MikaelHoogen/home-assistant
active_config_path: esphome/regnlogger-nimbus.yaml
active_git_commit: <sha>
firmware_version: <version>
esphome_version: <version>
framework: esp-idf
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do
hardware_revision: <om känd>
input_verification_result: passed | failed | pending
```

Detta gör att aktiv drift, referenskod och dokumenterad målbild inte kan glida isär utan att avvikelsen blir synlig.
