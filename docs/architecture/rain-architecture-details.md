# Regnobservatoriets arkitekturdetaljer

Status: Migrerad och omstrukturerad från tidigare regnobservatorie-dokumentation

## 1. Målbild

Systemet ska vara ett lokalt skyfallsobservatorium, inte bara en regnmätar-dashboard.

Det ska kunna:

1. ta emot råa och aggregerade nederbördsobservationer från flera mätkällor,
2. lagra rådata spårbart och oförändrat,
3. normalisera observationer till jämförbara tidsserier,
4. beräkna regnvolym för rullande och fasta varaktigheter,
5. beräkna intensitet i mm/h,
6. identifiera och beskriva regnhändelser,
7. klassificera regn mot SMHI- och Dahlström-/Svenskt Vatten-underlag,
8. stödja både dagens och klimatjusterade trösklar,
9. visa både återkomstklass och interpolerat återkomstestimat,
10. jämföra flera mätare,
11. flagga mätosäkerhet, metodskillnad och TB4-sifonrelaterad tidsosäkerhet,
12. publicera begripliga nyckeltal till Home Assistant,
13. ge möjlighet till djupanalys i Grafana,
14. bygga en långsiktig lokal extremvärdesdatabas,
15. på lång sikt kunna beräkna egna lokala IDF-samband.

## 2. Systemflöde

```text
Regnmätare / Netatmo / testscenario
→ ESPHome / Netatmo API / testgenerator
→ MQTT / API-ingest
→ AppDaemon
→ TimescaleDB/PostgreSQL
→ normaliserade tidsserier
→ rullande och fasta varaktigheter
→ regnhändelser
→ IDF-/återkomstklassning
→ analysmoduler
→ Home Assistant / Grafana
→ långsiktigt lokalt IDF-arkiv
```

I den bredare hydromet-arkitekturen är detta regnmodulens flöde ovanpå `hydromet core`.

## 3. Grundfilosofi

### Rådata är helig

Råa pulser och råa observationer ska aldrig skrivas över, förenklas bort eller ersättas av tolkade värden.

Alla hydrologiska tolkningar ska ske i separata lager ovanpå rådata.

```text
Rådata → normalisering → beräkning → klassning → presentation
```

### Stabil kärna, modulär analys

```text
Rådata är stabil.
Normaliserade tidsserier är stabila.
Allt ovanpå är modulärt och versionerat.
```

Nya idéer ska kunna läggas till som analysmoduler, vyer eller resultatrader utan att rådatamodellen behöver byggas om.

## 4. Observationsserier för regnmodulen

Systemet ska stödja flera parallella observationsserier:

| Serie | Typ | Upplösning | Roll |
|---|---|---:|---|
| `tb4_logger_ha` | TB4 tipping bucket, sifonmatad | puls | nuvarande huvudkälla |
| `tb4_puls` | separat framtida TB4-råpuls | puls | framtida huvudkälla |
| `netatmo_cloud` | Netatmo via moln/API | ca 5 min | jämförelse och extra indikation |
| `netatmo_puls` | framtida egen råpuls | puls | framtida tidsfördelning |
| `logger_test` | syntetisk/test | puls/scenario | permanent test- och scenariokälla |
| `composite_best_estimate` | bearbetad serie | framtida | bästa uppskattning med flera källor |

## 5. TB4 och korttidsosäkerhet

TB4 är en sifonmatad tipping bucket. Den kan vara bra som volymmässig huvudkälla, men mycket korta tidsfördelningar behöver tolkas försiktigt eftersom sifonen kan batcha vatten innan vippan registrerar pulser.

Designregel:

```text
TB4 5 min = diagnostik/indikativt.
TB4 15 min = användbart men med kvalitetsflagga.
TB4 60–720 min = mer robust.
```

## 6. Varaktigheter

Officiella analysvaraktigheter:

```text
15, 30, 45, 60, 120, 360, 720, 1440 minuter
```

Diagnostisk extra-varaktighet:

```text
5 minuter
```

5 minuter ska finnas som nice-to-have och diagnostik, men inte vara bärande återkomstklass för TB4.

## 7. Rullande och fasta fönster

Systemet ska stödja både:

```text
rolling_window
fixed_clock_window
```

Rullande fönster används för lokal händelseanalys och maxvärden. Fasta klockfönster används för jämförelse mot aggregerade datakällor som Netatmo cloud och SMHI-liknande tidsserier.

## 8. IDF och klassning

Systemet ska stödja flera parallella referensmetoder:

```text
SMHI_Klimatologi_47
SMHI_Klimatologi_47_climate_adjusted
Dahlstrom_2010
Dahlstrom_2010_climate_adjusted
P110
Dahlstrom_2018, senare
local_idf, långsiktigt
```

Varje klassning ska kunna ge:

```text
return_period_class
return_period_est_years
method
idf_version
climate_mode
duration_min
rain_mm
quality_class
method_uncertainty
```

Klimatjusterad klassning ska beskrivas som jämförelse mot klimatjusterade trösklar, inte som exakt framtida återkomsttid.

## 9. Regnhändelser

Regnhändelser ska byggas från början och vara en central analysprodukt.

Varje händelse ska kunna bära:

```text
start/slut
total mm
varaktighet
max per varaktighet
mest extrem varaktighet
högsta återkomstklass
händelsetyp
peak position
mätaröverensstämmelse
TB4-sifonflagga
skyfallsdefinition uppfylld/ej uppfylld/osäker
sammanfattningstext
```

## 10. Analysmoduler

Planerade moduler:

```text
rolling_durations
return_period_classification
event_detection
event_fingerprint
gauge_agreement
tb4_siphon_diagnostics
skyfall_definition
near_skyfall_indicator
duration_profile
method_disagreement
seasonal_profile
antecedent_rain
runoff_risk_index
manual_effect_observations
meter_health
local_idf_long_term
```

Moduler ska kunna ha status:

```text
disabled
experimental
active
deprecated
```

## 11. Ingen framåtextrapolerande varning

Systemet ska inte ha en modul som säger:

```text
Om nuvarande takt fortsätter når vi X om Y minuter.
```

Detta riskerar att bli prognosliknande och ge falsk precision.

Tillåtet:

```text
Senaste 15 min motsvarar 82 % av 10-årsnivån.
Senaste 60 min är 76 % av skyfallströskeln.
Mest extrem varaktighet hittills är 30 min.
```

## 12. Home Assistant som presentationslager

Home Assistant är primärt presentationslager. HA ska visa färdiga states och attribut från SQL/AppDaemon/MQTT, inte bära tung hydrologisk logik.

Exempel på HA-sensorer:

```text
sensor.regn_aktuell_handelse_total_mm
sensor.regn_aktuell_handelse_start
sensor.regn_aktuell_handelse_varaktighet
sensor.regn_mest_extrem_varaktighet
sensor.regn_maxklass_aktuell_handelse
sensor.regn_aterkomstklass_smhi
sensor.regn_aterkomstklass_dahlstrom
sensor.regn_aterkomstklass_smhi_klimat
sensor.regn_nara_skyfall_procent
sensor.regn_mataroverensstammelse
sensor.regn_tb4_korttidskvalitet
sensor.regn_systemhalsa
```

## 13. Internt regn-API / MQTT till HA

För att HA ska vara stabilt bör färdiga sammanfattningar publiceras som JSON via MQTT eller AppDaemon.

Exempel:

```text
rain/summary/current
rain/event/current
rain/event/latest
rain/classification/current
rain/diagnostics
rain/system_health
```

## 14. Grafana senare

Grafana används som fördjupningslager för:

```text
regn per minut
kumulativ händelsevolym
rullande varaktigheter
varaktighetsprofil
återkomstklass över tid
TB4 vs Netatmo
mätaröverensstämmelse
POT-kandidater
årsmax per varaktighet
lokal IDF på lång sikt
```

## 15. Lokal IDF på lång sikt

Systemet ska från början byggas så att det om 10, 20 eller 40 år kan användas för lokal extremvärdesanalys.

Det kräver:

```text
rådata sparas långsiktigt
mätuppställningar versioneras
datagap loggas
testdata hålls isär
kvalitetsflaggor sparas
årsmax sparas per varaktighet
POT-kandidater kan extraheras
IDF-modeller versioneras
historik kan reklassas
```

Lokal IDF ska inte ersätta SMHI/Dahlström tidigt, men systemet ska samla rätt data från dag ett.

## 16. Slutlig målbild

Systemet ska vara byggt för nyfikenhet, inte för att bli färdigt.
