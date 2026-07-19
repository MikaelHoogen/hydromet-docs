# Fördjupade observatoriefunktioner och utforskning

Status: Planerad målbild / konceptuell specifikation

## 1. Syfte

Detta dokument samlar funktioner som gör regnobservatoriet användbart som ett långsiktigt lokalt observationsarkiv, inte bara som en beräkningsmotor eller realtidsdashboard.

Funktionerna bygger ovanpå befintliga kärnobjekt:

```text
rain_events
rain_event_duration_profile
rain_return_period_results
rain_effect_observations
rain_measurement_setups
rain_analysis_results
```

De ska kunna läggas till modulärt utan att rådatamodellen ändras.

## 2. Händelsearkiv och händelsekort

### Syfte

Varje avslutad regnhändelse ska kunna visas som ett beständigt händelsekort i ett lokalt regnarkiv.

Ett händelsekort bör kunna innehålla:

```text
event_id
start- och sluttid
total nederbörd
varaktighet
mest extrem varaktighet
full varaktighetsprofil
återkomstklass enligt vald metod
jämförelse mellan SMHI och Dahlström
klimatjusterad jämförelse
händelsetyp
peak position
mätaröverensstämmelse
TB4-korttidskvalitet
manuella effektobservationer
sammanfattningstext
```

Händelsekortet är en presentation av befintliga strukturerade resultat. Det ska inte bli den primära lagringsformen.

Möjliga presentationer:

```text
Home Assistant-historik
Grafana-tabell
Markdown-rapport
CSV- eller JSON-export
framtida RainLens-rapport
```

Designregel:

```text
Arkivet ska länka tillbaka till strukturerade resultat och rådata, inte ersätta dem.
```

## 3. Lokala topplistor

### Syfte

Systemet ska kunna visa lokala topplistor utan att antyda att den korta lokala serien redan utgör egen återkomststatistik.

Planerade listor:

```text
årets största 15-minutersregn
årets största 30-minutersregn
årets största 60-minutersregn
årets största 6-timmarsregn
årets största totalvolym per händelse
årets högst klassade händelser
hela mätseriens största händelser
```

Varje listpost bör innehålla:

```text
rank
event_id
datum
duration_min
rain_mm
return_period_class
method
quality_class
measurement_setup_version
```

Designregel:

```text
Lokal topplista är observationshistorik, inte lokal IDF.
```

## 4. Lokal säsongsprofil

### Syfte

Med tiden ska observatoriet kunna beskriva hur den lokala regnaktiviteten varierar över året.

Exempel på sammanställningar per månad eller säsong:

```text
total nederbörd
antal regnhändelser
median händelsevolym
största händelse
högsta värde per varaktighet
antal händelser över vald extern återkomstnivå
torrperiodernas längd
datatäckning
```

Resultaten är deskriptiva och ska skiljas från extremvärdesmodellering.

Kvalitetskrav:

```text
redovisa datatäckning
redovisa aktiv mätuppställning
markera ofullständiga månader och år
håll testdata utanför produktionsprofilen
```

## 5. Scenariobibliotek för analys- och beräkningstest

### Syfte

`logger_test` ska kunna använda ett versionshanterat bibliotek av syntetiska regnscenarier för att prova hela analyskedjan.

Detta är separat från teknisk verifiering av verkliga Nimbus och `hydromet.rain_logger_test_events`.

Ett scenario bör beskriva:

```text
scenario_id
scenario_version
description
series_id
is_test = true
input_resolution
start_time_strategy
total_mm
duration_min
temporal_pattern
expected_duration_maxima
expected_event_boundaries
expected_classification_range
expected_quality_flags
source_or_rationale
```

Exempel på scenarier:

```text
jämnt 10 mm-regn på 15 minuter
kort intensiv cell
framtung händelse
baktung händelse
dubbelpeak
långvarigt frontliknande regn
TB4-dubbelpulsmönster
Netatmo-liknande oregelbundna intervall
händelse med datagap och återhämtad mängd
```

Scenarier ska kunna köras om när beräkningsversioner ändras.

Designregel:

```text
Teknisk loggerverifiering och analysverifiering är två olika testdomäner.
```

## 6. Kalibrerings-, kontroll- och underhållshistorik

### Syfte

En mätuppställning behöver mer än en fri anteckning om kalibrering. Systemet ska på lång sikt kunna bära en kronologisk historik över sådant som påverkar mätseriens tolkning.

Planerat objekt:

```text
rain_measurement_setup_actions
```

Konceptuella fält:

```text
action_id
setup_id
series_id
time
action_type
performed_by
result
reference_value
measured_value
adjustment
notes
photo_reference
document_reference
creates_new_setup_version
metadata
```

Exempel på `action_type`:

```text
calibration_check
manual_tip_test
cleaning
inspection
relocation
mounting_change
wind_shield_change
sensor_replacement
logger_replacement
firmware_change
repair
known_fault
return_to_service
```

En fysisk förändring som påverkar mätförutsättningarna ska normalt skapa en ny `measurement_setup_version`. En enkel kontroll eller rengöring kan registreras utan ny version när uppställningen är oförändrad.

## 7. Händelselikhet

### Syfte

Händelsefingeravtrycket ska senare kunna användas för att hitta historiska händelser som liknar en aktuell eller vald händelse.

Planerad modul:

```text
event_similarity
```

Möjliga jämförelsevariabler:

```text
total_mm
duration_min
normaliserad tidsprofil
maxvärden per varaktighet
andel i intensivaste 15 och 30 minuter
peak_position_percent
number_of_peaks
event_type
antecedent_condition_class
```

Möjligt resultat:

```text
source_event_id
similar_event_id
similarity_score
similarity_method
feature_version
explanation
quality_class
```

Exempel på presentation:

```text
Den här händelsen liknar mest regnet 2028-07-14.
Likheten drivs främst av en baktung tvåtoppig profil och liknande 30-/60-minutersmax.
```

Designregel:

```text
Likhet är en explorativ jämförelse, inte meteorologisk kausalitet eller statistisk klassning.
```

## 8. Home Assistant-flöde för manuell effektobservation

### Syfte

Efter en relevant regnhändelse ska Home Assistant kunna be användaren komplettera mätdata med en enkel observation av faktisk lokal effekt.

Exempel på val:

```text
ingen synlig avrinning
vatten i dike
stående vatten
flöde över väg
problem vid byggnad
översvämning i lågpunkt
inlopp igensatt
pump eller brunn påverkad
```

Föreslaget flöde:

```text
händelse avslutas
→ systemet bedömer om observation bör efterfrågas
→ HA visar notis eller formulär
→ användaren väljer effektklass och kan lägga till text/foto
→ observationen sparas i rain_effect_observations
→ händelsekortet uppdateras
```

En observation ska alltid bära:

```text
observer
tid
plats
effect_class
severity
fri text
foto- eller dokumentreferens
```

Designregler:

```text
Ingen utebliven användarobservation får tolkas som att ingen effekt inträffade.
Manuell observation ska hållas isär från automatiska sensorvärden.
```

## 9. Modulstatus

Föreslagen initial status:

| Funktion | Status |
|---|---|
| Händelsearkiv och händelsekort | planned |
| Lokala topplistor | planned |
| Lokal säsongsprofil | planned |
| Scenariobibliotek | planned |
| Kalibrerings- och underhållshistorik | planned |
| Händelselikhet | experimental / future |
| HA-flöde för effektobservation | planned |

## 10. Relation till andra dokument

- [Regnmodulens analysmoduler](rain-analysis-modules.md) beskriver modulernas övergripande katalog.
- [Regnmodulens konceptuella datamodell](../architecture/rain-data-model-details.md) beskriver kärnobjekt och generiska resultatlager.
- [Regnobservatoriets arkitekturdetaljer](../architecture/rain-architecture-details.md) beskriver målbilden och systemets lager.
- [Roadmap](../roadmap.md) styr när funktionerna prioriteras.

## 11. Avgränsning

Detta dokument beskriver målbild och informationsmodell. Det innebär inte att funktionerna är implementerade eller verifierade.

Testning och aktuell operativ verifiering dokumenteras i respektive runbook och genomförs i separat arbetsflöde.