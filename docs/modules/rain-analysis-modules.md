# Regnmodulens analysmoduler

Status: Migrerad och omstrukturerad från tidigare regnobservatorie-dokumentation

## 1. Princip

Systemet ska byggas som ett modulärt analysramverk. Nya idéer ska kunna läggas till som nya moduler utan att rådatamodellen ändras.

Varje modul bör ha:

```text
module_name
module_version
status
input
output
quality_rules
ha_output
grafana_output
notes
```

Statusvärden:

```text
disabled
experimental
active
deprecated
```

## 2. Kärnmoduler

### `rolling_durations`

Status: planned  
Syfte: Beräkna rullande regnvolymer och intensitet för valda varaktigheter.

Input:

```text
rain_timeseries_1min
rain_timeseries_5min
```

Output:

```text
rain_duration_values
```

Varaktigheter:

```text
5, 15, 30, 45, 60, 120, 360, 720, 1440 minuter
```

5 minuter är diagnostisk/nice-to-have.

### `fixed_clock_windows`

Status: planned  
Syfte: Beräkna fasta klockfönster för jämförelse mot aggregerade datakällor.

Input:

```text
rain_timeseries_1min
rain_timeseries_5min
```

Output:

```text
rain_duration_values
```

### `return_period_classification`

Status: planned  
Syfte: Klassificera uppmätt regn mot IDF-/tröskelunderlag.

Input:

```text
rain_duration_values
idf_thresholds
```

Output:

```text
rain_return_period_results
```

Ska stödja:

```text
SMHI_Klimatologi_47
Dahlstrom_2010
klimatjusterade trösklar
klass och interpolerat estimat
```

### `event_detection`

Status: planned  
Syfte: Dela in regn i händelser.

Input:

```text
rain_timeseries_1min
rain_timeseries_5min
```

Output:

```text
rain_events
```

Regler ska versioneras, exempelvis torruppehåll före/efter händelse.

### `event_duration_profile`

Status: planned  
Syfte: Beräkna maxvärde per varaktighet för varje händelse.

Input:

```text
rain_events
rain_duration_values
```

Output:

```text
rain_event_duration_profile
```

Detta är en av systemets viktigaste analysprodukter.

## 3. Händelseförståelse

### `dominant_duration`

Status: planned  
Syfte: Identifiera vilken varaktighet som är mest extrem relativt vald metod.

Output:

```text
dominant_duration_min
max_return_period_class
max_return_period_est_years
```

### `event_fingerprint`

Status: planned  
Syfte: Skapa ett fingeravtryck för varje regnhändelse.

Exempel på resultat:

```text
total_mm
duration_min
max_15min_mm
max_30min_mm
share_in_max_15min
peak_position_percent
number_of_peaks
event_type
gauge_agreement_score
tb4_siphon_uncertainty
```

### `event_type_classification`

Status: planned  
Syfte: Typa händelser.

Exempel:

```text
kort intensiv cell
långvarigt frontliknande regn
dubbelpeak
framtungt regn
baktungt regn
lågintensivt långt regn
osäker TB4-korttidsprofil
testscenario
```

### `event_report_generator`

Status: planned  
Syfte: Skapa sammanfattningstext efter avslutad händelse.

Output:

```text
summary_text
```

Exempel:

```text
Regnhändelse avslutad. Total nederbörd 31,6 mm. Mest extrem varaktighet 30 min. Klass 10–20 år enligt SMHI SV.
```

## 4. Skyfall och återkomst

### `skyfall_definition`

Status: planned  
Syfte: Hålla isär SMHI:s skyfallsdefinition från återkomstklassning.

Output:

```text
skyfallsdefinition_uppfylld
skyfallsdefinition_ej_uppfylld
skyfallsdefinition_osäker
```

TB4:s 1-minutsdel ska hanteras försiktigt.

### `near_skyfall_indicator`

Status: planned  
Syfte: Visa hur nära en händelse är skyfallströskel.

Exempel:

```text
38 / 50 mm på 60 min = 76 %
```

### `duration_radar`

Status: planned  
Syfte: Visa händelsens varaktighetsprofil relativt vald återkomstnivå.

Exempel:

```text
15 min: 82 % av 10-årsnivå
30 min: 104 % av 10-årsnivå
60 min: 66 % av 10-årsnivå
```

### `return_period_momentum`

Status: planned  
Syfte: Visa hur extremiteten förändras bakåtblickande under pågående händelse.

Ska inte extrapolera framåt.

## 5. Mätare och kvalitet

### `gauge_agreement`

Status: planned  
Syfte: Jämföra flera mätserier.

Exempel:

```text
TB4 vs Netatmo cloud
TB4 logger_ha vs tb4_puls
TB4 vs composite_best_estimate
```

Output:

```text
difference_mm
difference_percent
agreement_class
quality_flags
```

### `tb4_siphon_diagnostics`

Status: planned  
Syfte: Flagga korttidsosäkerhet kopplad till TB4:s sifonmatade mätprincip.

Möjliga indikatorer:

```text
antal dubbelpulser
kortaste pulsintervall
median pulsintervall
pulsgruppsindex
långt uppehåll följt av flera pulser
stor avvikelse mot annan mätare
```

Output:

```text
tb4_short_duration_confidence
tb4_siphon_uncertainty_flag
bucket_pattern_summary
```

### `meter_health`

Status: planned  
Syfte: Övervaka mätarkedjans funktion.

Indikatorer:

```text
senaste TB4-puls
senaste MQTT-meddelande
senaste DB-rad
senaste Netatmo cloud-uppdatering
förväntad vs faktisk uppdateringsfrekvens
AppDaemon-status
TimescaleDB-status
```

Output:

```text
OK
varning
fel
okänd
```

## 6. Metodskillnader

### `method_disagreement`

Status: planned  
Syfte: Visa om SMHI och Dahlström ger olika klassning.

Output:

```text
class_smhi
class_dahlstrom
estimate_smhi
estimate_dahlstrom
method_disagreement_level
```

Metodosäkerhet betyder inte att någon metod är fel, utan att referensramarna ger olika tolkning.

## 7. Lokal hydrologisk kontext

### `antecedent_rain`

Status: planned  
Syfte: Ge händelsen kontext i form av torrperiod och förregn.

Output:

```text
dry_period_before_h
rain_24h_before_mm
rain_3d_before_mm
rain_7d_before_mm
rain_14d_before_mm
antecedent_condition_class
```

### `runoff_risk_index`

Status: experimental  
Syfte: Lokal observationsbaserad indikator för avrinningsrisk.

Viktigt: detta är en egen teknisk tolkning, inte SMHI- eller Svenskt Vatten-fakta.

Input:

```text
pågående regn
rullande varaktigheter
förregn
torrperiod
händelsetyp
manuella effektobservationer
```

Output:

```text
låg
måttlig
hög
mycket hög
```

### `manual_effect_observations`

Status: planned  
Syfte: Koppla regndata till verklig effekt på platsen.

Exempel:

```text
ingen synlig avrinning
vatten i dike
stående vatten
flöde över väg
problem vid byggnad
översvämning i lågpunkt
```

## 8. Koppling till skyfallskartering

### `skyfall_mapping_context`

Status: planned / future  
Syfte: Koppla uppmätta regnhändelser till skyfallskarteringsscenarier, modellregn, återkomsttid, klimatfaktor, varaktighet och lokal effektobservation.

Källa/metodreferens:

```text
MSB2260 — Metod för skyfallskartering av tätorter
```

Input:

```text
rain_events
rain_event_duration_profile
rain_return_period_results
rain_effect_observations
rain_mapping_scenarios
```

Output:

```text
rain_event_mapping_comparison
```

Exempel på tolkning:

```text
uppmätt händelse under valt karteringsscenario
uppmätt händelse nära valt karteringsscenario
uppmätt händelse över valt karteringsscenario
jämförelse osäker på grund av mätar-/tidsupplösning
```

Designregel:

```text
Skyfallskartering ska vara ett konsekvens- och scenarielager, inte en ersättning för IDF-kärnan.
```

## 9. Klimatprediktorbaserad IDF

### `climate_predictor_idf`

Status: planned / future / experimental  
Syfte: Kunna jämföra lokalt uppmätta regnhändelser mot en klimatprediktorbaserad IDF-/klimatfaktormetod, där plats, klimatprediktorer, scenario, RCP, tidsperiod och metodversion kan ingå som metadata.

Källa/metodreferens:

```text
SVU-projekt 14–105 — Regnintensitet i ett förändrat klimat i Sverige med data tillgängliga för användare
Dahlström 2018
```

Input:

```text
rain_events
rain_event_duration_profile
rain_return_period_results
idf_thresholds
idf_climate_predictor_estimates
rain_local_idf_estimates, långsiktigt
```

Output:

```text
climate_predictor_return_period_comparison
idf_climate_predictor_estimates
```

Exempel på metadata:

```text
plats/gridcell
klimatmodell
regional modell
RCP/scenario
tidsperiod
klimatprediktorer
klimatfaktor
beräkningsregn
metodversion
kvalitetsklass
```

Designregel:

```text
Klimatprediktorbaserad IDF ska vara en framtida jämförelsemetod, inte en ersättning för den första IDF-kärnan.
```

## 10. Historik och lokal IDF

### `annual_maxima`

Status: planned  
Syfte: Spara årets största värde per varaktighet.

Output:

```text
rain_annual_maxima
```

### `pot_candidates`

Status: planned  
Syfte: Spara kandidater för framtida Peak-over-Threshold-analys.

Output:

```text
rain_pot_candidates
```

### `data_completeness`

Status: planned  
Syfte: Bedöma om år är tillräckligt kompletta för framtida lokal extremvärdesanalys.

Output:

```text
rain_data_completeness
```

### `local_idf_long_term`

Status: disabled / long-term  
Syfte: Beräkna lokal IDF när observationsserien är tillräckligt lång.

Tidshorisont: 10–40 år och framåt.
