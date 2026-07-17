# Hårdvaruförteckning

Status: Levande förteckning

## Syfte och dokumentgräns

Hårdvaruförteckningen beskriver fysiska logger- och I/O-enheter som kan användas i Hydromet/RainLens.

Den är styrande för:

```text
hårdvarumodeller
fysiska plintar och ingångar
interna hårdvarubindningar
elektriska och tekniska egenskaper
```

Den beskriver inte MQTT-payloads, retained-regler, räknarlogik eller den fullständiga installationen.

Relaterade dokument:

- [MQTT-meddelanden och loggerkontrakt](../architecture/mqtt-message-contract.md) beskriver transportkontraktet.
- [Nivå 1-design för regnlogger](../architecture/level-1-logger-design.md) beskriver loggerns beteende.
- [Regnobservatoriet](../modules/rain-observatory.md) beskriver regnmodulen.
- [Sännesholma Nimbus](../installations/sannesholma-nimbus.md) beskriver den konkreta installationen.
- [Waveshare ESP32-S3-POE-ETH-8DI-8DO](waveshare-esp32-s3-poe-eth-8di-8do.md) beskriver den aktuella hårdvaran.

## Princip

Dokumentationen ska hålla isär:

```text
RainLens-kontrakt
→ konkret installation
→ hårdvarumodell
→ intern teknisk bindning
```

RainLens/Hydromet ska inte göra GPIO, Modbus-register, I2C-portar eller andra interna kopplingar till en del av det generella observationskontraktet.

Det generella kontraktet använder stabila identiteter:

```text
site_id
logger_id
channel_id
sensor_id
```

En konkret installation beskriver vilken fysisk ingång som används för en viss logisk kanal och, där det är relevant, vilka ytterligare fältanslutningar som krävs. Hårdvaruförteckningen beskriver sedan hur just den ingången är uppbyggd internt på den valda modellen.

## Tre informationsnivåer

### 1. Kontrakt

```yaml
site_id: sannesholma
logger_id: nimbus
channel_id: rain_1
sensor_id: tb4_0p2
```

Kontraktet använder den logiska kanalidentiteten `rain_1` och behöver inte känna till plint eller GPIO.

### 2. Installation

```yaml
site_id: sannesholma
logger_id: nimbus
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do
channels:
  rain_1:
    physical_input: DI1
    field_return: DGND
    sensor_id: tb4_0p2
    mm_per_tip: 0.2
```

Installationen säger att `rain_1` använder `DI1` och, för just denna passiva kontaktkrets, returterminalen `DGND` på den valda hårdvarumodellen.

### 3. Hårdvarumodell

```yaml
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do
physical_inputs:
  DI1:
    label: IN1
    passive_contact_return: DGND
    external_supply_required: false
    hardware_binding:
      type: gpio
      value: GPIO4
      recommended_mode:
        input: true
        pullup: true
      inverted: true
```

Hårdvarumodellen löser `DI1` till den interna bindningen `GPIO4` och beskriver även relevant elektrisk retur, polaritet och rekommenderad GPIO-vilonivå.

## Begrepp

### `channel_id`

Abstrakt och stabil kanalidentitet i Hydromet/RainLens, till exempel `rain_1`.

### `physical_input`

Fysisk ingång på den hårdvarumodell som loggern använder, till exempel `DI1`, `IN1`, `input_0` eller `A0`.

Värdet tolkas alltid tillsammans med `hardware_model`.

### `field_return`

Valfri installationsmetadata för den terminal som sluter den avsedda fältslingan när en sådan retur är relevant och entydig.

För Nimbus passiva kontakt på den aktuella Waveshare-modellen är detta `DGND`, motsvarande den fysiska plint som är märkt `GND` i gruppen **Digital Inputs**. Det är inte `DICOM/COM` och inte ESP32-logikjord.

Alla framtida gränssnitt har inte en enda meningsfull returterminal. Seriella bussar, differentiella signaler, strömloopar och andra I/O-typer kan därför behöva andra anslutningsfält än `field_return`.

### `hardware_binding`

Intern teknisk koppling i hårdvarumodellen, till exempel `GPIO4`, Modbus discrete input address 0 eller IO-expander port A0.

Bindningen används av firmware eller drivrutin, men är inte kanalens identitet i RainLens-kontraktet.

En robust bindning bör vid behov även beskriva:

```text
input/output mode
pull-up eller pull-down
aktiv nivå
inversion
```

### `DICOM/COM`

Common-terminal för aktivt externt spänningsmatad digital ingång på den aktuella Waveshare-modellen. På den fysiska plinten är den märkt `COM`. Den används inte som retur för Nimbus potentialfria TB4-kontakt.

### `DGND`

Dokumentationsnamn för retur på den isolerade digitala fältsidan. På den fysiska plinten är den märkt `GND` under **Digital Inputs**. TB4 ska sluta `DI1` mot denna terminal.

Denna `GND` får inte blandas ihop med ESP32-logikjord.

## Designregel

```text
channel_id är kontrakt.
physical_input är installationsmappning mot vald hårdvarumodell.
field_return är valfri fysisk anslutningsmetadata där sådan retur är relevant.
hardware_binding är hårdvarumodellens interna teknik.
```

Det gör att samma RainLens-kanal kan flyttas mellan olika hårdvaror utan att MQTT-topic, observationskontrakt eller databasmodell behöver göras om.

## Aktuell registrerad Nimbus-modell

```text
Waveshare ESP32-S3-POE-ETH-8DI-8DO
```

Kanonisk identitet:

```text
waveshare_esp32_s3_poe_eth_8di_8do
```

Äldre identitet `waveshare_esp32_s3_eth_8di_8ro` är fel för Nimbus och ska endast betraktas som legacyreferens.
