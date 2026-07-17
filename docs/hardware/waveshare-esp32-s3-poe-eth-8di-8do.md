# Waveshare ESP32-S3-POE-ETH-8DI-8DO

Status: Verifierad hårdvarumodell för Nimbus / målkonfiguration under bänkverifiering

## 1. Syfte och dokumentgräns

Denna sida beskriver den exakta Waveshare-modell som används av Nimbus:

```text
Waveshare ESP32-S3-POE-ETH-8DI-8DO
```

Sidan är styrande för:

```text
modellidentitet
fysiska ingångsplintar
passiv respektive aktiv ingångskoppling
intern bindning DI1 → GPIO4
GPIO-polaritet och rekommenderad vilonivå
```

Den beskriver inte MQTT-payloads, räknarpersistens eller hela Nimbus-installationen.

Relaterade dokument:

- [Hårdvaruförteckning](index.md)
- [Nimbus-installationen](../installations/sannesholma-nimbus.md)
- [Verifiering av DI1-ingången](../runbooks/nimbus-di1-verification.md)
- [Nivå 1-design för regnlogger](../architecture/level-1-logger-design.md)

## 2. Exakt modellidentitet

```yaml
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do
hardware_family: esp32_s3
manufacturer: Waveshare
part_number: ESP32-S3-POE-ETH-8DI-8DO
network_capability:
  - ethernet
  - poe
input_type: isolated_digital_input
input_count: 8
output_type: isolated_digital_output
output_count: 8
```

Modellen får inte blandas ihop med:

```text
ESP32-S3-ETH-8DI-8RO
ESP32-S3-POE-ETH-8DI-8RO
andra Waveshare-varianter med reläutgångar
```

`8DO` betyder digitala transistorutgångar. `8RO` avser reläutgångar och är en annan produkt.

## 3. Digitala ingångar

Waveshares officiella wiki anger följande interna bindningar:

```yaml
physical_inputs:
  DI1:
    hardware_binding:
      type: gpio
      value: GPIO4
  DI2:
    hardware_binding:
      type: gpio
      value: GPIO5
  DI3:
    hardware_binding:
      type: gpio
      value: GPIO6
  DI4:
    hardware_binding:
      type: gpio
      value: GPIO7
  DI5:
    hardware_binding:
      type: gpio
      value: GPIO8
  DI6:
    hardware_binding:
      type: gpio
      value: GPIO9
  DI7:
    hardware_binding:
      type: gpio
      value: GPIO10
  DI8:
    hardware_binding:
      type: gpio
      value: GPIO11
```

För Nimbus gäller därmed:

```text
RainLens-kanal rain_1
→ fysisk ingång DI1 / IN1
→ intern bindning GPIO4
```

`GPIO4` är inte kanalens identitet i RainLens-kontraktet. Det är den här hårdvarumodellens interna bindning för `DI1`.

## 4. Terminalernas roller och faktiska plintmärkning

Waveshares kopplingsdiagram använder symbolnamnen `DGND` och `DICOM`. På den fysiska plinten är motsvarande terminaler märkta `GND` och `COM` i gruppen **Digital Inputs**.

```text
Dokumentsymbol DGND  = fysisk plint GND under Digital Inputs
Dokumentsymbol DICOM = fysisk plint COM under Digital Inputs
```

Den fysiska `GND`-plinten i ingångsgruppen är alltså inte ESP32-logikjord.

### `DI1`

Fältingång för digital ingång 1.

### `DGND` / fysisk plint `GND`

Retur på den isolerade digitala fältsidan. En potentialfri kontakt ska sluta respektive `DIx` mot den fysiska `GND`-plinten under **Digital Inputs**.

### `DICOM` / fysisk plint `COM`

Gemensam terminal för aktivt, externt spänningsmatad ingång. Waveshares diagram använder denna vid 5–36 V aktiv ingång.

`DICOM/COM` är inte rätt returterminal för KISTERS TB4:s potentialfria kontakt.

### ESP32-`GND`

Logikjord på processorsidan. Den ska inte användas som retur för TB4-signalen.

## 5. Passiv ingång: potentialfri kontakt

Waveshares officiella diagram för passiv eller dry-contact-ingång visar kontakten mellan `DIx` och `DGND`, det vill säga den fysiska `GND`-plinten under **Digital Inputs**.

För Nimbus blir kopplingen:

```text
KISTERS TB4 ledare 1 ───────── DI1
KISTERS TB4 ledare 2 ───────── GND under Digital Inputs
                               └─ DGND i diagram/dokumentation

COM under Digital Inputs       oansluten
ESP32-GND                      oansluten
extern ingångsmatning          ingen
```

TB4:s kontaktledare är en potentialfri reedkontakt. Ledarnas inbördes polaritet saknar därför normalt betydelse.

Följande är inte korrekt dry-contact-koppling:

```text
DI1 ↔ COM/DICOM
DI1 ↔ ESP32-GND
```

## 6. Varifrån kommer matningen?

Waveshare anger att kortet har integrerad kraftisolation som ger en isolerad terminalmatning och att ingen extra matning behövs för den isolerade terminalgruppen.

Funktionellt är signalvägen:

```text
kortets systemmatning / PoE
→ intern isolerad DC/DC-omvandling
→ separat matad fältsida
→ ingångskrets och optokopplare
→ DI1
→ sluten TB4-kontakt
→ GND/DGND
```

Galvaniskt isolerad betyder alltså inte omatad. Energi överförs till en separat fältsida utan en avsiktlig DC-förbindelse till ESP32-sidan.

Ett fullständigt officiellt komponentnivåschema har inte påträffats. Följande är därför inte fastställt från offentlig dokumentation:

- exakt ingångsmotstånd,
- exakt loopström,
- exakt filter- och skyddsnät,
- om GPIO4 redan har ett externt kortmonterat pull-up-motstånd och dess värde,
- indikatorlysdiodens exakta placering i signalvägen.

## 7. GPIO4: polaritet och pull-up

Den isolerade ingången presenteras för ESP32 på `GPIO4`. ESPHome Devices-referensen för denna kortfamilj använder `INPUT_PULLUP` och `inverted: true` för de digitala ingångarna. RainLens/Hydromets målkonfiguration för Nimbus är därför:

```yaml
pin:
  number: GPIO4
  mode:
    input: true
    pullup: true
  inverted: true
```

Rollerna ska hållas isär:

```text
DI1–GND/DGND = fältsidans strömväg genom TB4-kontakten
pull-up       = GPIO4:s definierade vilonivå på ESP32-sidan
```

Pull-up:

- matar inte TB4,
- lägger inte 3,3 V på DI1-plinten,
- ersätter inte kopplingen till `GND/DGND`,
- håller GPIO4 stabilt hög när optokopplarutgången är inaktiv.

När optokopplaren aktiveras förväntas den elektriska GPIO-nivån dras låg. Med `inverted: true` presenteras detta som logiskt `ON`.

| TB4-kontakt | Elektrisk GPIO4 | ESPHome efter inversion |
|---|---:|---:|
| Öppen | HIGH | OFF |
| Sluten | LOW | ON |

Ett komplett kortschema saknas, så dokumentationen påstår inte att kortet definitivt saknar en extern pull-up. Intern pull-up är en beslutad målkonfiguration och ska bänkverifieras på den faktiska enheten.

ESPHome Devices är en plattformsspecifik implementationsreferens, inte tillverkarens komponentnivåschema. Evidenskedjan är därför:

```text
Waveshare
→ DI1 till GPIO4 och dry contact till GND/DGND

ESPHome Devices
→ INPUT_PULLUP och inverted för digitalingångarna

RainLens/Hydromet
→ målkonfiguration som verifieras praktiskt
```

## 8. Varför en lös tråd eller ett finger kan ge pulser

En fri ledning på `DI1` eller `GND/DGND` är inte en giltig kontaktslutning. Den fungerar som antenn. När en person håller i ledningen kan kroppskapacitans koppla in nätfrekventa och högfrekventa störningar.

Galvanisk isolation blockerar en avsiktlig DC-ledning mellan fältsida och logiksida, men inte all kapacitiv common-mode-koppling eller snabba transienter.

Två felmekanismer ska skiljas åt:

1. Störningen når optokopplaringången på fältsidan.
2. GPIO4 saknar en tillräckligt definierad vilonivå och växlar efter optokopplaren.

DI1-indikatorn och GPIO-diagnostiken ska observeras samtidigt under felsökning. En fri ledning som berörs med fingret får aldrig användas som bevis för korrekt ingångsfunktion.

Intern pull-up kan stabilisera logiksidan men kan inte garantera att en lång öppen fältledning aldrig aktiverar optokopplaringången genom störning. Löskabeltestet är därför diagnostiskt och inte ett acceptanstest.

## 9. Aktiv ingång

Waveshare stöder även aktivt spänningsmatad ingång på 5–36 V. Den kopplingsformen använder den fysiska `COM`-plinten (`DICOM` i diagrammet) och en extern källa enligt Waveshares wet-contact-diagram.

Den behövs inte för KISTERS TB4 och ingår inte i Nimbus normala installation.

## 10. Evidensnivå

### Verifierat från officiell Waveshare-dokumentation

- exakt produktmodell,
- åtta isolerade digitala ingångar och åtta digitala utgångar,
- passiv och aktiv ingång stöds,
- integrerad isolerad terminalmatning utan extra matning,
- `DI1 → GPIO4`,
- passiv kontakt kopplas mellan `DIx` och `DGND`, motsvarande fysisk `GND`-plint under **Digital Inputs**.

### Verifierat från KISTERS

- TB4 Series II använder spänningsfri reedkontakt som pulsutgång,
- kontakten sluts när mekanismen tippar,
- mätaren har dubbel reedutgång,
- reedkontakten är inte garanterat studsfri,
- reedutgången har varistorskydd mot inducerade överspänningar,
- Nimbus-mätaren ger 0,2 mm per vippning enligt installationens metadata.

### Plattformsspecifik implementationsreferens

- ESPHome Devices använder pull-up och inversion för kortets digitala ingångar.
- Referensen stödjer målkonfigurationen men ersätter inte bänkverifiering eller ett komponentnivåschema.

### Beslutad RainLens/Hydromet-målkonfiguration

- `DI1–GND/DGND` för TB4,
- ingen extern ingångsmatning,
- `GPIO4` som ingång,
- intern pull-up,
- aktiv låg med `inverted: true`,
- kontrollerat bänktest före fältdrift.

## 11. Källor

- Waveshare, produktsida: <https://www.waveshare.com/ESP32-S3-POE-ETH-8DI-8DO.htm>
- Waveshare, wiki och GPIO-mappning: <https://www.waveshare.com/wiki/ESP32-S3-POE-ETH-8DI-8DO>
- Waveshare, dry-/wet-contact-diagram och fysisk plintmärkning: <https://www.waveshare.com/img/devkit/accBoard/ESP32-S3-POE-ETH-8DI-8DO/ESP32-S3-POE-ETH-8DI-8DO-details-9.jpg>
- KISTERS, TB4 Series II: <https://products.kisters.net/products/hardware/meteorology/tb4-tipping-bucket-rain-gauge>
- KISTERS, installationsguide TB3/TB4/TB7: <https://cdnproducts.kisters.net/fileadmin/Meteorology/TB3/Downloads/IG_TB3_TB4_TB7_en.pdf>
- ESPHome Devices, Waveshare ESP32-S3 ETH 8DI 8DO: <https://devices.esphome.io/devices/waveshare-esp32-s3-eth-8di-8do/>
- ESPHome, GPIO binary sensor: <https://esphome.io/components/binary_sensor/gpio/>
- ESPHome, pin modes: <https://esphome.io/guides/configuration-types/>
