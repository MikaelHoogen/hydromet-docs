# Waveshare ESP32-S3 ETH 8DI 8RO

Status: Första hårdvarumodell för Nimbus

## Syfte

Denna sida beskriver den fysiska och interna ingångsmappningen för Waveshare ESP32-S3 ETH/PoE med 8 digitala ingångar och 8 utgångar.

Syftet är att hålla hårdvarans interna kopplingar separerade från RainLens/Hydromet-kontraktet.

## Hårdvarumodell

```yaml
hardware_model: waveshare_esp32_s3_eth_8di_8ro
hardware_family: esp32_s3
input_type: opto_isolated_digital_input
input_count: 8
```

## Digitala ingångar

Enhetens digitala ingångar används som `physical_input` i installationsmappningen.

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

## Rekommenderad första regnkanal

För Nimbus används första digitala ingången:

```yaml
channel_id: rain_1
physical_input: DI1
resolved_hardware_binding:
  type: gpio
  value: GPIO4
```

Detta betyder:

```text
RainLens-kanal rain_1
→ fysisk ingång DI1 / IN1 på Waveshare-enheten
→ intern ESP32-S3-bindning GPIO4
```

## Designregel

```text
GPIO4 är inte en del av RainLens-kontraktet.
GPIO4 är hårdvarumodellens interna bindning för DI1.
```

Installationen ska därför normalt peka på `physical_input: DI1`, inte hårdkoda `GPIO4` som primär kanalidentitet.

## Kommentarer

DI1–DI4 använder GPIO4–GPIO7 och är lämpliga första val för enkla pulsingångar.

DI5–DI8 använder GPIO8–GPIO11. De kan vara användbara, men bör väljas med medvetenhet om alternativa funktioner på ESP32-S3.

Strapping-, USB- och JTAG-relaterade pinnar ska undvikas för regnpulser där det finns renare ingångar.
