# Vision: svensk regnobservationsplattform

Status: Framtidsvision / långtidsidé  
Syfte: Dokumentera idén att projektet på sikt skulle kunna växa från ett lokalt skyfallsobservatorium till en mer generell svensk plattform för regnobservationer, IDF-jämförelser och mätseriekvalitet.

## 1. Grundidé

Det lokala skyfallsobservatoriet byggs först för en plats och en egen mätkedja.

På längre sikt kan samma arkitektur generaliseras till något större:

```text
En öppen, modern och spårbar plattform för lokal regnstatistik,
IDF-jämförelser, klimatfaktorer, regnhändelser och kvalitetsklassade regnobservationer i Sverige.
```

Detta ska inte påverka MVP. Visionen dokumenteras för att arkitekturen redan från början inte ska låsa fast projektet vid en enda privat installation.

## 2. Inte en kopia av DHI/SVU-tjänsten

Målet är inte att direkt kopiera DHI:s/SVU:s tjänst.

DHI/SVU-tjänsten är en viktig förebild genom att den visar värdet av en platsbaserad tjänst för klimatprediktorer, klimatfaktorer, beräkningsregn och återkomstbedömning av egna regndata.

En framtida svensk regnobservationsplattform skulle däremot kunna ha ett annat fokus:

```text
mätning
rådata
metadata
mätarkvalitet
datatäckning
händelser
återkomstklassning
metodjämförelse
lokal effektobservation
långtidsarkiv
```

Det är mer en regnobservatorieplattform än en ren IDF-kalkylator.

## 3. Möjlig framtida tjänst

En framtida publik eller halvpublik tjänst skulle kunna innehålla:

```text
IDF-kalkylator för valfri plats
SMHI/Klimatologi 47-regioner
Dahlström 2010
klimatjusterade trösklar
Dahlström 2018 / klimatprediktorbaserad metod, som framtida jämförelse
uppladdning av egen regnserie
automatisk händelsedetektering
automatisk återkomstklassning
jämförelse mellan lokal mätning och nationell statistik
mätar- och metodmetadata
kvalitetsklassning av mätserier
datatäckningsanalys
lokala årsmax och POT-kandidater
på sikt: seriösa crowdsourcade regnstationer
```

## 4. Det som skulle göra plattformen unik

Många befintliga verktyg fokuserar på dimensionerande regn eller enstaka IDF-beräkningar.

Den här visionen bygger på hela kedjan:

```text
observation
rådata
mätarkedja
kvalitet
varaktigheter
händelser
metoder
klassning
effektobservation
historik
lokal statistik
```

En central användarfråga skulle kunna vara:

```text
Här är min regnserie.
Hur bra är den?
Vilka händelser sticker ut?
Vad motsvarar de enligt SMHI?
Vad motsvarar de enligt Dahlström?
Hur skiljer sig metoderna?
Vilken datatäckning har jag?
När kan min serie börja användas för lokal statistik?
```

## 5. Utvecklingsväg

Möjlig utvecklingsväg:

```text
Steg 1: Bygg för en egen plats.
Steg 2: Gör datamodellen generell.
Steg 3: Gör IDF-/metodmotorn fristående.
Steg 4: Gör ett internt API.
Steg 5: Gör ett publikt API.
Steg 6: Gör en webbapp.
Steg 7: Låt andra ladda upp eller ansluta mätserier.
Steg 8: Bygg kvalitetsklassning, metadata och datatäckningskontroll.
Steg 9: Bygg jämförelser mellan lokala mätserier och nationell statistik.
```

Den egna installationen fungerar då som:

```text
referensanläggning
proof of concept
testbädd
metodutvecklingsmiljö
```

## 6. Centrala byggblock

Befintliga eller planerade byggblock som stödjer visionen:

```text
rain_series_registry
rain_measurement_setups
rain_tip_events
rain_interval_observations
rain_timeseries_1min
rain_timeseries_5min
rain_duration_values
idf_thresholds
rain_return_period_results
rain_events
rain_event_duration_profile
rain_system_health
rain_system_alerts
rain_effect_observations
rain_annual_maxima
rain_pot_candidates
rain_data_completeness
rain_local_idf_estimates
idf_climate_predictor_estimates
rain_mapping_scenarios
rain_event_mapping_comparison
```

I hydromet core motsvaras flera av dessa av generella kärnobjekt och regnspecifika moduler.

## 7. Möjligt publikt API

På sikt kan en fristående metodmotor exponeras som API.

Exempel:

```text
/rain/idf
/rain/methods
/rain/regions
/rain/event/classify
/rain/event/compare-methods
/rain/series/quality
/rain/series/data-completeness
/rain/series/annual-maxima
/rain/series/pot-candidates
```

Exempel på frågetyp:

```text
Ge mig 15, 30, 60 och 120 min återkomstklass för denna regnhändelse,
med SMHI/Klimatologi 47, Dahlström 2010 och klimatjusterad jämförelse.
```

## 8. Kvalitet och förtroende

Det svåra med en svensk plattform är inte främst webben eller API:t.

Det svåra är:

```text
metodansvar
källor
kvalitetssäkring
juridiska förbehåll
tydlig skillnad mellan normgivande och experimentellt
hantering av dåliga mätdata
mätarmetadata
datatäckning
långsiktig drift
förtroende
```

Därför måste alla resultat bära:

```text
metod
version
källa
plats/region
varaktighet
återkomsttid
klimatläge
scenario/tidsperiod, om relevant
mätarupplösning
kvalitetsklass
osäkerhetsnotering
```

## 9. Förhållande till nuvarande projekt

Nuvarande projekt ska fortsatt byggas som ett lokalt regnobservatorium.

Men följande principer gör det möjligt att växa senare:

```text
undvik hårdkodning för en enda plats
använd serieregister
versionera mätuppställningar
versionera metoder
håll rådata separat från beräkningar
lagra kvalitet och metadata
skilj normgivande, jämförande och experimentella metoder
bygg moduler i stället för engångslösningar
```

## 10. Roadmap-placering

Visionen ligger efter de ordinarie projektfaserna.

Föreslagen framtida fas:

```text
Fas 7: Nationell/platsgenerell plattform
```

Innehåll:

```text
generalisera från egen plats till valfri plats
fristående IDF-/metodmotor
publikt API
webbapp
uppladdning av egna regnserier
kvalitetsklassning av mätdata
datatäckningsanalys
lokala jämförelser mot nationell statistik
möjlighet till anslutna seriösa regnstationer
```

## 11. Designregler

```text
Bygg först ett mycket bra lokalt observatorium.
```

```text
Gör arkitekturen tillräckligt generell för att inte stänga dörren till en större plattform.
```

```text
En framtida svensk plattform ska vara spårbar, metodmedveten och kvalitetsklassad.
```

```text
Publika resultat ska skilja tydligt mellan normgivande metod, jämförelsemetod och experimentell metod.
```

```text
Crowdsourcade eller uppladdade regnserier ska aldrig blandas med kvalitetssäkrade referensdata utan tydlig klassning.
```
