# Regnmodulens konceptuella datamodell

Status: Migrerad och omstrukturerad från tidigare regnobservatorie-dokumentation

## 1. Princip

Den ursprungliga regnmodellen delades i lager:

```text
1. Rådata
2. Register och metadata
3. Normaliserade tidsserier
4. Beräknade varaktigheter
5. Regnhändelser
6. Klassning och analysresultat
7. Långsiktig lokal IDF
```

I hydromet-modellen motsvaras rådata och register av generell core, medan regnspecifika objekt byggs ovanpå.

## 2. Rådata

### `rain_tip_events`

Råa tipping-bucket-pulser.

Princip:

```text
En puls = en rad.
```

Konceptuella fält:

```text
time
received_at
source
sensor_id
series_id
event
mm
pulse_total
raw_pulse_total
ignored_pulse_total
uptime_ms
interval_ms
gpio
time_valid
epoch_s
topic
payload
```

I hydromet core kan detta mappas till:

```text
hydromet.event_observations
```

### `rain_interval_observations`

Aggregerade observationer, till exempel Netatmo cloud.

Konceptuella fält:

```text
time_start
time_end
received_at
source
sensor_id
series_id
rain_mm
resolution_min
payload
quality_flags
```

I hydromet core kan detta mappas till:

```text
hydromet.interval_observations
```

## 3. Register och metadata

### `rain_series_registry`

Register över observationsserier.

```text
series_id
source_type
sensor_id
meter_type
resolution
is_raw_pulse
is_interval_series
is_test
is_primary
quality_baseline
measurement_setup_version
active_from
active_to
description
metadata
```

I hydromet core motsvaras detta av:

```text
hydromet.observation_series
```

### `rain_measurement_setups`

Versionering av mätuppställningar.

```text
setup_version
series_id
meter_model
meter_resolution_mm
location_description
height_above_ground
wind_shield
mounting
logger_type
signal_path
installed_at
retired_at
calibration_notes
known_limitations
metadata
```

I hydromet core motsvaras detta av:

```text
hydromet.measurement_setups
```

### `rain_config_versions`

Versionering av beräkningsantaganden.

```text
config_version
valid_from
description
idf_version
climate_factor_version
event_detection_version
quality_rules_version
module_versions
notes
```

## 4. Normaliserade tidsserier

### `rain_timeseries_1min`

Minutserie för råpulskällor.

```text
bucket_time
series_id
sensor_id
rain_mm
tip_count
quality_class
quality_flags
source_resolution
calculation_version
```

### `rain_timeseries_5min`

5-minutersserie för Netatmo cloud och andra aggregerade källor.

```text
bucket_time
series_id
sensor_id
rain_mm
resolution_min
quality_class
quality_flags
payload_reference
```

## 5. Rullande och fasta varaktigheter

### `rain_duration_values`

Generell tabell eller vy för rullande och fasta fönster.

```text
time
series_id
duration_min
window_type
window_start
window_end
rain_mm
intensity_mm_h
quality_class
calculation_version
```

`window_type` kan vara:

```text
rolling_window
fixed_clock_window
```

Officiella varaktigheter:

```text
15, 30, 45, 60, 120, 360, 720, 1440 minuter
```

Diagnostiskt:

```text
5 minuter
```

## 6. IDF- och tröskelunderlag

### `idf_thresholds`

```text
idf_version
method
source_reference
region
duration_min
return_period_year
rain_mm
climate_factor
rain_mm_climate_adjusted
valid_from
valid_to
notes
```

Metoder från start:

```text
SMHI_Klimatologi_47
SMHI_Klimatologi_47_climate_adjusted
Dahlstrom_2010
Dahlstrom_2010_climate_adjusted
P110
```

Framtida:

```text
Dahlstrom_2018
local_idf
local_idf_climate_adjusted
experimental_thresholds
```

## 7. Klassning

### `rain_return_period_results`

```text
time
series_id
duration_min
window_type
method
idf_version
climate_mode
rain_mm
return_period_class
return_period_est_years
quality_class
method_uncertainty
calculated_at
```

## 8. Regnhändelser

### `rain_events`

```text
event_id
series_id
start_time
end_time
duration_min
total_mm
dry_gap_before_min
dry_gap_after_min
quality_class
event_type
dominant_duration_min
max_return_period_class
max_return_period_est_years
method
climate_mode
summary_text
metadata
```

### `rain_event_duration_profile`

Händelsens fulla varaktighetsprofil.

```text
event_id
series_id
duration_min
window_type
max_rain_mm
max_intensity_mm_h
window_start
window_end
return_period_class
return_period_est_years
method
climate_mode
quality_class
```

## 9. Analysmoduler

### `rain_analysis_modules`

```text
module_name
module_version
description
input_requirements
output_type
status
notes
```

Status:

```text
disabled
experimental
active
deprecated
```

### `rain_analysis_results`

Generiskt resultatlager för nya idéer.

```text
time
module_name
module_version
series_id
event_id
duration_min
method
climate_mode
quality_class
numeric_value
text_value
result_json
calculated_at
```

## 10. Långsiktig lokal IDF

### `rain_annual_maxima`

```text
year
series_id
duration_min
max_rain_mm
max_intensity_mm_h
event_id
window_start
window_end
quality_class
completeness_score
measurement_setup_version
calculation_version
```

### `rain_pot_candidates`

```text
series_id
duration_min
threshold_mm
rain_mm
event_id
window_start
window_end
independence_gap_h
is_independent
quality_class
calculation_version
```

### `rain_data_completeness`

```text
year
series_id
days_with_data
missing_days_total
missing_days_may_sep
longest_gap_h
critical_season_coverage
completeness_score
quality_class
notes
```

### `rain_extreme_value_models`

```text
model_id
series_id
duration_min
method
distribution
fit_period_start
fit_period_end
n_years
n_events
parameters_json
confidence_intervals_json
diagnostics_json
created_at
model_version
```

### `rain_local_idf_estimates`

```text
series_id
duration_min
return_period_year
rain_mm
intensity_mm_h
method
model_id
uncertainty_low_mm
uncertainty_high_mm
data_period
quality_class
```

## 11. Manuell effektobservation

### `rain_effect_observations`

```text
observation_id
event_id
time
observer
effect_class
description
photo_reference
location
severity
metadata
```

Exempel på `effect_class`:

```text
ingen synlig avrinning
vatten i dike
stående vatten
flöde över väg
problem vid byggnad
översvämning i lågpunkt
```
