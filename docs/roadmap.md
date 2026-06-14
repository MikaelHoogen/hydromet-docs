# Roadmap

Status: Levande plan

## Fas 0: Hydromet kärnmodell

Mål: skapa en generell observationsgrund som kan bära regn, nivå, flöde, markfukt, vind och framtida sensorer.

```text
1. hydromet schema
2. observation_series
3. measurement_setups
4. point_observations
5. interval_observations
6. event_observations
7. system_health
8. system_alerts
9. mappning från befintlig public.rain_tip_events
10. regnmodul ovanpå hydromet core
```

## Fas 1: Stabil regngrund

```text
1. Observationsserier för TB4, Netatmo och testkällor
2. Rådata från TB4/logger_ha som event_observations
3. logger_test permanent som scenariokälla
4. Netatmo cloud som interval_observations
5. Mätarkedjans hälsa
6. Normaliserad minutserie / 5-minserie
7. Officiella varaktigheter
8. Rullande och fasta summeringar
9. IDF-trösklar för SMHI och Dahlström
10. Klimatjusterade trösklar
```

## Fas 2: Händelser och klassning

```text
1. Händelsedetektering
2. Händelsemax per varaktighet
3. Mest extrem varaktighet
4. Återkomstklass
5. Interpolerat återkomstestimat
6. Skyfallsdefinition
7. Nära-skyfall
8. HA-sammanfattning
```

## Fas 3: Diagnos och jämförelse

```text
1. Mätaröverensstämmelse
2. TB4-sifon-/bucketdiagnostik
3. Mätarkedjans hälsa
4. Metodskillnad SMHI/Dahlström
5. Metodosäkerhet
6. Scenariobibliotek för logger_test
```

## Fas 4: Fler hydromet-domäner

```text
1. nivå i damm/brunn/dike
2. flöde i utlopp/inlopp
3. markfukt
4. vind
5. regndetektion
6. vattenkvalitet
7. pumpstatus / bräddning / tömningstid
```

## Fas 5: Historik och lokal IDF

```text
1. Årsmax per varaktighet
2. POT-kandidater
3. Datatäckning per år
4. Mätuppställningsversioner
5. Lokala topplistor
6. Lokal säsongsprofil
7. Extremvärdesmodeller
8. Lokala IDF-estimat
9. Reklassning av historik
```

## Fas 6: Dokumentation och publicering

```text
1. MkDocs-struktur
2. ADR-beslut
3. Modulkatalog
4. GitHub Pages
5. Ren uppdelning mellan hydromet-docs och home-assistant
```
