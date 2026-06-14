# ADR-0002: `logger_test` är permanent scenariokälla

## Status

Accepted

## Bakgrund

Systemet ska kunna utvecklas och testas utan att vänta på verkligt regn. Tidigare testkedja har visat att syntetiska pulser kan användas för att verifiera MQTT, AppDaemon, TimescaleDB, SQL, Home Assistant och framtida Grafana-paneler.

## Beslut

`logger_test` ska ingå permanent i arkitekturen som scenariokälla.

Den ska kunna användas för att simulera exempelvis:

```text
kort intensiv cell
långt frontliknande regn
dubbelpeak
TB4-dubbelpuls
TB4-sifonkluster
Netatmo 5-minutersblock
extremt 15-minutersregn
långvarigt 6–12-timmarsregn
```

## Konsekvenser

Fördelar:

- hela kedjan kan testas utan verkligt regn,
- klassning och händelselogik kan verifieras,
- HA-sensorer kan testas kontrollerat,
- framtida ändringar kan regressionstestas.

Krav:

- testdata måste alltid hållas isär från skarpa data,
- testdata får aldrig ingå i riktiga återkomsttidsberäkningar,
- `is_test`, `series_id` och `sensor_id` ska vara tydliga.
