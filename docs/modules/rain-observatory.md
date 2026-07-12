# Regnobservatorium

Status: Första modul / aktiv utveckling

## 1. Syfte

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

## 2. Primära datakällor

```text
TB4/logger_ha
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

## 4. Nimbus-installation

Första produktionsnära regnloggern kallas Nimbus.

```yaml
site_id: sannesholma
logger_id: nimbus
ha_prefix: regnlogger_nimbus
hardware_model: waveshare_esp32_s3_eth_8di_8ro
```

Första regnkanal:

```yaml
channels:
  rain_1:
    physical_input: DI1
    sensor_id: tb4_0p2
    sensor_type: tipping_bucket
    mm_per_tip: 0.2
```

Tolkning:

```text
rain_1 = RainLens/Hydromets logiska regnkanal
DI1    = fysisk ingång på Waveshare-enheten
GPIO4  = intern hårdvarubindning enligt hårdvaruförteckningen
```

Installationen ska normalt hänvisa till `physical_input: DI1`. Den interna kopplingen `DI1 → GPIO4` hör hemma i hårdvaruförteckningen för Waveshare-modellen.

## 5. Varaktigheter

Primära varaktigheter:

```text
15, 30, 45, 60, 120, 360, 720, 1440 minuter
```

5 minuter kan finnas som diagnostik/nice-to-have.

## 6. IDF och återkomstklassning

Första metodfamiljer:

```text
SMHI Klimatologi 47
Dahlström 2010
klimatjusterade trösklar
```

Framtida/jämförande:

```text
Dahlström 2018
klimatprediktorbaserad IDF
lokal IDF
```

## 7. Designprincip

```text
Regnanalys byggs ovanpå hydromet core.
Rådata skrivs aldrig över.
Historik ska kunna reklassas när metoder eller trösklar ändras.
```
