# Källor och underlag

Detta dokument samlar de källor och projektunderlag som arkitekturen bygger på.

## 1. Princip

Källor ska delas upp efter roll:

```text
normgivande metod
jämförelsemetod
framtida/experimentell metod
bakgrund och konsekvensförståelse
```

Designregel:

```text
Resultat ska alltid kunna kopplas till metod, källa och version.
```

## 2. Projektunderlag

### Regnlogger → MQTT → AppDaemon → TimescaleDB

Sammanfattning av mätkedjan:

```text
Regnmätare / reedkontakt
→ ESPHome-logger
→ MQTT
→ AppDaemon
→ TimescaleDB/PostgreSQL
→ SQL/Grafana/Home Assistant-beräkningar
```

Viktiga principer:

- varje tipp sparas som en rad,
- rå datainsamling separeras från beräkning och visualisering,
- testlogger används för att simulera pulser och scenarier,
- TB4 är sifonmatad och korta tidsfördelningar behöver tolkas försiktigt.

### HA/SMHI/IDF/återkomsttid

Sammanfattning av konceptet:

```text
regnpuls → mm → tidsserie → rullande varaktigheter → intensitet → återkomsttid
```

Viktiga principer:

- valda varaktigheter ska kopplas till SMHI/Dahlström,
- återkomsttid kan visas både som klass och interpolerat värde,
- klimatfaktor ska stödjas,
- Home Assistant ska visa förenklade nyckeltal,
- Grafana kan användas för fördjupning.

## 3. SMHI

### Klimatologi 47 — Extremregn i nuvarande och framtida klimat

Viktigt för:

- regional skyfallsstatistik,
- regionerna SV, SÖ, M och N,
- fokus på korttidsnederbörd upp till 12 timmar,
- framtida klimatförändring,
- skyfallsdefinition och korttidsstatistik.

### Bilaga II — Extremvärdesstatistik och osäkerhet

Viktigt för:

- återkomsttid,
- årsmaxmetoden,
- Peak over Threshold, POT,
- tolkning av återkomsttid,
- extremvärdesfördelningar.

### Bilaga III — Analys av högupplöst nederbördsdata från SMHI:s automatstationer

Viktigt för:

- IDF-bearbetning,
- regntillfällen,
- maximal medelintensitet per varaktighet,
- skillnad mellan vägande mätare och vippmätare,
- fasta 15-minutersdata.

### Bilaga IV — Klusteranalyser för regional indelning

Viktigt för:

- regional indelning,
- stabilitet för regioner mellan 15 min och 6 timmar.

### Bilaga V — Statistisk analys av skyfallsegenskaper i tid och rum

Viktigt för:

- regnets typform,
- när toppintensiteten inträffar inom en händelse,
- rumslig korrelation.

### Bilaga VI — Ny formel för skyfallsstatistik

Viktigt för:

- analytisk formel för regnvolym som funktion av varaktighet och återkomsttid,
- regionparametrar,
- korrigering för fasta tidsfönster genom `M(V)`,
- stöd för godtyckliga varaktigheter.

### Bilaga X — Historiska variationer av extrem korttidsnederbörd

Viktigt för:

- regionala årshögsta,
- frekvens av överskridanden,
- historisk variation.

### Bilaga XI — Klimatscenarier med högupplösta regionala klimatmodeller

Viktigt för:

- framtida klimatförändring,
- klimatfaktorer/förändringsprocent,
- jämförelser mellan scenarier.

## 4. Svenskt Vatten

### Rapport 2010-05 — Regnintensitet, Bengt Dahlström

Viktigt för:

- Dahlström 2010,
- dimensionerande regnintensitet,
- varaktigheter från 5 minuter till 24 timmar,
- konvektiva och frontala regn.

### SVU-projekt 14–105 — Regnintensitet i ett förändrat klimat i Sverige med data tillgängliga för användare

Slutrapport januari 2019. Författare: Claes Hernebring, Bengt Dahlström och Erik Kjellström.

Viktigt för:

- klimatprediktorbaserad utveckling av IDF-/regnintensitetsmetodik,
- Dahlström 2018,
- platsbaserad klimatfaktor,
- beräkningsregn,
- scenario/RCP/tidsperiod,
- utvärdering av egna regndata,
- framtida jämförelsemetod i systemets IDF-arkitektur.

Användning i projektet:

```text
SVU 2019 används som framtida klimatprediktorbaserad IDF-/jämförelsemetod.
Den används inte som första normgivande IDF-kärna.
```

### P110

Viktigt för:

- dimensionering av dagvattensystem,
- funktionskrav,
- klimatfaktor,
- återkomsttid i dagvattensammanhang.

### M148 — Nederbördsstatistik för dimensionering av dagvattensystem, State of the art

Viktigt för:

- rekommendation att tills vidare använda Dahlström 2010 vid dimensionering,
- jämförelse mellan SMHI:s statistik och Dahlström,
- klimatfaktor minst 1,25 för regn kortare än en timme och minst 1,20 för längre regn för anläggningar i slutet av århundradet,
- att rekommendationer kan ändras med ny kunskap.

## 5. MSB

### MSB2260 — Metod för skyfallskartering av tätorter

Publikation: MSB2260, november 2023.  
Titel: *Metod för skyfallskartering av tätorter*.

Viktigt för:

- koppling mellan uppmätta regnhändelser och skyfallskarteringsscenarier,
- metodval för skyfallskartering,
- scenario- och modellmetadata,
- kvalitetsgranskning av karteringsresultat,
- dokumentation av antaganden,
- framtida koppling mellan regnmätning, effektobservationer och ytlig avrinning vid skyfall.

Användning i projektet:

```text
MSB2260 används inte som IDF-kärna.
Den används som referens för framtida konsekvens-, scenario- och skyfallskarteringskoppling.
```

## 6. Egna tekniska antaganden

Följande är designbeslut i detta projekt och inte källfakta:

- `logger_test` används permanent som scenariokälla.
- Netatmo cloud behandlas som egen 5-minuters intervallserie.
- TB4 är huvudvolymkälla men korta tidsfördelningar kvalitetsflaggas.
- Home Assistant prioriteras före Grafana som första presentationslager.
- Systemet ska vara modulärt och utbyggbart.
- Lokal IDF är ett långsiktigt mål, inte en tidig ersättning för SMHI/Dahlström.
- MSB2260 används som framtida scenario-/konsekvenslager, inte som ersättning för IDF-/mätkärnan.
- SVU 2019/Dahlström 2018 används som framtida klimatprediktorbaserad jämförelsemetod, inte som första normgivande IDF-kärna.
