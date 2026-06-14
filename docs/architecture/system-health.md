# Systemhälsa och larm

Status: Arkitektur / målbild

## 1. Syfte

Systemet ska kunna skilja mellan:

```text
ingen nederbörd
mätare utan pulser
logger offline
MQTT-problem
AppDaemon-problem
databasproblem
moln/API-fördröjning
```

Hälsodata är därför en del av kärnmodellen, inte bara en regnmodul.

## 2. Princip

```text
Larma först på förlorade livstecken.
Jämför därefter mätserier.
```

Frånvaro av regnpulser är inte i sig ett fel. Frånvaro av heartbeat/status kan däremot vara ett fel.

## 3. Föreslagna objekt

```text
hydromet.system_health
hydromet.system_alerts
```

## 4. Komponenter

Exempel:

```text
tb4_logger_ha
logger_test
netatmo_cloud
mqtt_ingest
appdaemon_ingest
timescaledb
ha_summary_publish
wind_station
pond_level_logger
soil_moisture_logger
```

## 5. Hälsosignaler

```text
online/offline
senaste heartbeat
senaste mottagna observation
senaste databasskrivning
batteri
signalstyrka
firmware
uptime
antal accepterade pulser
antal råpulser
antal ignorerade pulser
```

## 6. Larmfilosofi

Larm ska formuleras som misstänkta avvikelser, inte absoluta sanningar.

Exempel:

```text
logger offline
heartbeat saknas
MQTT tar inte emot data
AppDaemon skriver inte till databas
Netatmo cloud fördröjt
TB4 och Netatmo avviker mer än väntat
```

## 7. Regnmodulens specialfall

För regn kan systemhälsan senare användas för att bedöma:

```text
TB4 online men inga pulser trots regnindikation
Netatmo rapporterar regn men TB4 inte
TB4 rapporterar regn men Netatmo cloud inte
pulsglapp i pulse_total
onormalt många ignorerade råpulser
```

Alla sådana jämförelser ska vara beroende av att mätkedjan först bedöms som levande.
