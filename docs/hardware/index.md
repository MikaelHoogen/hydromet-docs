# Hårdvaruförteckning

Status: Levande förteckning

## Syfte

Hårdvaruförteckningen beskriver fysiska logger- och I/O-enheter som kan användas i Hydromet/RainLens.

Den ska hålla isär:

```text
RainLens-kontrakt
→ hårdvarumodell
→ konkret installation
```

## Princip

RainLens/Hydromet ska inte göra GPIO, Modbus-register, I2C-portar eller andra interna kopplingar till en del av det generella observationskontraktet.

Det generella kontraktet använder stabila identiteter:

```text
site_id
logger_id
channel_id
sensor_id
```

Hårdvaruförteckningen beskriver hur en viss hårdvarumodells fysiska ingångar är uppbyggda.

En konkret installation beskriver sedan vilken fysisk ingång som används för en viss logisk kanal.

## Tre lager

### 1. Kontrakt

```yaml
site_id: sannesholma
logger_id: nimbus
channel_id: rain_1
sensor_id: tb4_0p2
```

### 2. Hårdvarumodell

```yaml
hardware_model: waveshare_esp32_s3_eth_8di_8ro
physical_inputs:
  DI1:
    label: IN1
    hardware_binding:
      type: gpio
      value: GPIO4
```

### 3. Installation

```yaml
logger_id: nimbus
site_id: sannesholma
hardware_model: waveshare_esp32_s3_eth_8di_8ro
channels:
  rain_1:
    physical_input: DI1
    sensor_id: tb4_0p2
    mm_per_tip: 0.2
```

## Begrepp

```text
channel_id
```

Abstrakt och stabil kanalidentitet i Hydromet/RainLens, till exempel `rain_1`.

```text
physical_input
```

Fysisk ingång på den hårdvarumodell som loggern använder, till exempel `DI1`, `IN1`, `input_0` eller `A0`.

```text
hardware_binding
```

Intern teknisk koppling i hårdvarumodellen, till exempel `GPIO4`, Modbus discrete input address 0 eller IO-expander port A0.

## Designregel

```text
channel_id är kontrakt.
physical_input är installationsmappning mot vald hårdvarumodell.
hardware_binding är hårdvarumodellens interna teknik.
```

Det gör att samma RainLens-kanal kan flyttas mellan olika hårdvaror utan att observationskontrakt, MQTT-topic eller databasmodell behöver göras om.
