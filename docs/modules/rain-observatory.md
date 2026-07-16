# Regnobservatorium

Status: Första modul / aktiv utveckling

## 1. Syfte och dokumentgräns

Regnobservatoriet är första konkreta modulen ovanpå hydromet core.

Målet är att bygga lokal regnloggning med:

```text
rådata från mätare
spårbar mätuppställning
normaliserade tidsserier
rullande varaktigheter
IDF-jämförelse
återkomstklassning
regnhändelser
```

Detta dokument beskriver modulens datakällor, den konkreta Nimbus-installationen och den framtida regnanalysen.

Det är inte styrande för intern hårdvarumappning eller fullständiga MQTT-payloads:

- [Hårdvaruförteckningen](../hardware/index.md) beskriver fysisk ingång och intern bindning.
- [Nivå 1-designen](../architecture/level-1-logger-design.md) beskriver loggerns beteende och robusthetsnivå.
- [MQTT-kontraktet](../architecture/mqtt-message-contract.md) beskriver topics, schemas och retained-regler.

## 2. Primära datakällor

```text
Nimbus + TB4
logger_ha + TB4, historiskt kompatibilitetsspår
Netatmo cloud
logger_test
framtida regndropps-/regndetekteringssensor
```

## 3. Observationstyper

Tipping bucket-pulser:

```text
hydromet.event_observations
```

Moln/API-intervall:

```text
hydromet.interval_observations
```

Regndetektion:

```text
hydromet.event_observations
eller
hydromet.point_observations
```

Återhämtad mängd från ett räknarhopp får lagras, men ska bära kvalitetsinformation om att den exakta tidsfördelningen är osäker.

## 4. Nimbus-installation

Nimbus är den första regnloggern som byggs enligt Nivå 1: robust fältpilot, inte skottsäker produktionslogger.

```yaml
site_id: sannesholma
logger_id: nimbus
ha_prefix: regnlogger_nimbus
hardware_model: waveshare_esp32_s3_eth_8di_8ro

channels:
  rain_1:
    physical_input: DI1
    sensor_id: tb4_0p2
    sensor_type: tipping_bucket
    mm_per_tip: 0.2
```

Identiteterna betyder:

```text
sannesholma = platsen
nimbus      = den fysiska loggern
rain_1      = den logiska regnkanalen
tb4_0p2     = den anslutna mätaren
DI1         = fysisk ingång på vald hårdvarumodell
```

## 5. Upplöst hårdvarumappning

Installationen anger:

```text
hardware_model = waveshare_esp32_s3_eth_8di_8ro
physical_input = DI1
```

Hårdvaruförteckningen löser detta till:

```text
DI1 / IN1
→ GPIO4
```

Den kompletta kedjan för Nimbus är:

```text
TB4
→ Waveshare DI1 / IN1
→ GPIO4
→ lokal firmwarekomponent
→ channel_id rain_1
```

Installationen ska normalt lagra `physical_input: DI1`. `GPIO4` är intern metadata för Waveshare-modellen och får inte bli kanalidentitet i RainLens-kontraktet.

## 6. Operativ Nivå 1-profil

Nimbus ska följa [Nivå 1-designen](../architecture/level-1-logger-design.md).

Det innebär i sammanfattning:

```text
lokal pulse_total
lokal debounce/filterlogik
begränsad persistent räknare
retained channel state
non-retained live tip-event
periodisk heartbeat
ingestbaserad gap-detektering
synliga kvalitetsflaggor
```

Kanoniska topics och payloads definieras i [MQTT-kontraktet](../architecture/mqtt-message-contract.md).

### Lokal drift- och testdiagnostik

Nimbus får exponera skrivskyddad lokal diagnostik genom ESPHome Native API till Home Assistant, exempelvis ingångstillstånd, lokala räknare, uptime, tidstatus och anslutningsstatus.

Dessa entiteter är endast till för inkörning, driftöverblick och felsökning. De är inte observationskälla, inte en del av RainLens MQTT-kontrakt och inte grund för databasens återhämtning eller kvalitetsbedömning.

Nimbus ska därför fungera fullt ut även när Home Assistant eller Native API är otillgängligt. De styrande reglerna finns i [Nivå 1-designens avsnitt om Home Assistant-diagnostik](../architecture/level-1-logger-design.md#home-assistant-diagnostik).

## 7. Varaktigheter

Primära varaktigheter:

```text
15, 30, 45, 60, 120, 360, 720, 1440 minuter
```

5 minuter kan finnas som diagnostik eller kompletterande kort varaktighet.

## 8. IDF och återkomstklassning

Första metodfamiljer:

```text
SMHI Klimatologi 47
Dahlström 2010
klimatjusterade trösklar
```

Framtida och jämförande metoder:

```text
Dahlström 2018
klimatprediktorbaserad IDF
lokal IDF
```

## 9. Designprinciper

```text
Regnanalys byggs ovanpå hydromet core.
Rådata skrivs aldrig över.
Historik ska kunna reklassas när metoder eller trösklar ändras.
Loggerns tekniska begränsningar och tidsosäkerhet ska vara synliga i datakvaliteten.
Installation, hårdvarumodell och transportkontrakt ska hållas isär.
```
