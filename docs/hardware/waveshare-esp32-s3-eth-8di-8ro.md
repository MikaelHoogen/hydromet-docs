# Waveshare ESP32-S3 ETH 8DI 8RO

Status: Registrerad hårdvarumodell för Nimbus

## Syfte och dokumentgräns

Denna sida beskriver den fysiska och interna ingångsmappningen för Waveshare ESP32-S3 ETH/PoE med åtta digitala ingångar.

Sidan är styrande för:

```text
namn på fysiska ingångar
plintmärkning
intern mappning till ESP32-S3 GPIO
```

Den är inte styrande för vilken ingång en viss installation använder eller hur MQTT-meddelanden publiceras.

Relaterade dokument:

- [Hårdvaruförteckning](index.md)
- [Nimbus-installationen i regnobservatoriet](../modules/rain-observatory.md)
- [Nivå 1-design för regnlogger](../architecture/level-1-logger-design.md)

## Hårdvarumodell

```yaml
hardware_model: waveshare_esp32_s3_eth_8di_8ro
hardware_family: esp32_s3
network_capability:
  - ethernet
  - poe
input_type: isolated_digital_input
input_count: 8
```

## Digitala ingångar

Enhetens ingångsidentiteter används som `physical_input` i en konkret installation.

```yaml
physical_inputs:
  DI1:
    label: IN1
    hardware_binding:
      type: gpio
      value: GPIO4
  DI2:
    label: IN2
    hardware_binding:
      type: gpio
      value: GPIO5
  DI3:
    label: IN3
    hardware_binding:
      type: gpio
      value: GPIO6
  DI4:
    label: IN4
    hardware_binding:
      type: gpio
      value: GPIO7
  DI5:
    label: IN5
    hardware_binding:
      type: gpio
      value: GPIO8
  DI6:
    label: IN6
    hardware_binding:
      type: gpio
      value: GPIO9
  DI7:
    label: IN7
    hardware_binding:
      type: gpio
      value: GPIO10
  DI8:
    label: IN8
    hardware_binding:
      type: gpio
      value: GPIO11
```

## Uppslag från installation till firmware

En installation anger `hardware_model` och `physical_input`:

```yaml
hardware_model: waveshare_esp32_s3_eth_8di_8ro
physical_input: DI1
```

Hårdvaruförteckningen löser då:

```text
DI1 / IN1
→ GPIO4
```

Firmware kan därefter konfigurera den upplösta GPIO-bindningen som ingång.

## Nimbus-beslutet

Nimbus använder:

```yaml
channel_id: rain_1
physical_input: DI1
```

Detta är ett installationsbeslut för Nimbus, inte ett påstående om att `DI1` generellt är elektriskt bättre än övriga digitala ingångar på modellen.

Den kompletta kedjan blir:

```text
RainLens-kanal rain_1
→ fysisk ingång DI1 / IN1
→ intern bindning GPIO4
→ lokal pulsläsning enligt Nivå 1-designen
```

## Designregel

```text
GPIO4 är inte en del av RainLens-kontraktet.
GPIO4 är hårdvarumodellens interna bindning för DI1.
```

Installationen ska därför normalt peka på `physical_input: DI1`, inte hårdkoda `GPIO4` som primär kanalidentitet.

GPIO-numret får användas i den genererade eller enhetsspecifika firmwarekonfigurationen efter att hårdvaruuppslaget har gjorts.
