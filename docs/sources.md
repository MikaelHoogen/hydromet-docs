# Källor och underlag

Detta dokument samlar de källor och projektunderlag som arkitekturen bygger på.

## 1. Princip

Källor ska delas upp efter roll:

```text
normgivande metod
jämförelsemetod
framtida/experimentell metod
bakgrund och konsekvensförståelse
teknisk primärkälla
aktiv driftkälla
```

Designregel:

```text
Resultat ska alltid kunna kopplas till metod, källa och version.
Teknisk drift ska alltid kunna kopplas till aktiv konfigurationsfil och Git-commit.
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

## 3. Teknisk hårdvara och aktiv drift

### Waveshare ESP32-S3-POE-ETH-8DI-8DO

Officiell produktsida:

<https://www.waveshare.com/ESP32-S3-POE-ETH-8DI-8DO.htm>

Viktigt för:

- exakt modellidentitet och artikelnummer,
- åtta digitala ingångar och åtta digitala transistorutgångar,
- passiva och aktiva digitala ingångar,
- optokopplarisolation,
- integrerad kraftisolation,
- uppgift om att extra matning inte behövs för den isolerade terminalgruppen.

### Waveshare wiki och GPIO-mappning

<https://www.waveshare.com/wiki/ESP32-S3-POE-ETH-8DI-8DO>

Viktigt för:

```text
DI1 → GPIO4
DI2 → GPIO5
DI3 → GPIO6
DI4 → GPIO7
DI5 → GPIO8
DI6 → GPIO9
DI7 → GPIO10
DI8 → GPIO11
```

### Waveshare dry-/wet-contact-diagram

<https://www.waveshare.com/img/devkit/accBoard/ESP32-S3-POE-ETH-8DI-8DO/ESP32-S3-POE-ETH-8DI-8DO-details-9.jpg>

Viktigt för:

- passiv kontakt kopplas mellan `DIx` och `DGND`,
- `DICOM/COM` används i aktivt externt spänningsmatad ingång,
- KISTERS TB4 ska därför kopplas `DI1–DGND`,
- extern ingångsmatning behövs inte för TB4:s potentialfria kontakt.

### Begränsning i Waveshare-underlaget

Ett fullständigt officiellt komponentnivåschema för exakt modellen har inte påträffats i projektunderlaget.

Följande ska därför behandlas som mät- eller verifieringsfrågor, inte som fullt schemafastställda fakta:

- exakt ingångsmotstånd,
- exakt loopström,
- exakt filter- och skyddsnät,
- eventuell extern GPIO-pull-up och dess värde,
- indikatorlysdiodens exakta placering.

### KISTERS TB4 Series II

<https://products.kisters.net/products/hardware/meteorology/tb4-tipping-bucket-rain-gauge>

Viktigt för:

- korrekt tillverkare och modell,
- sifonmatad tipping bucket,
- dubbel reedutgång,
- varistorskydd mot inducerade överspänningar,
- tillgänglig upplösning 0,2 mm,
- potentialfri kontakt-/pulsutgång.

### ESPHome GPIO binary sensor och pin modes

- <https://esphome.io/components/binary_sensor/gpio/>
- <https://esphome.io/guides/configuration-types/>

Viktigt för:

- `binary_sensor` på GPIO,
- pin modes som `input` och `pullup`,
- inversion,
- flankhändelser genom `on_press`,
- behov av definierad elektrisk vilonivå för stabil ingång.

### Aktiv Nimbus-konfiguration

Aktiv avsedd driftkonfiguration finns i:

```text
MikaelHoogen/home-assistant
└── esphome/regnlogger-nimbus.yaml
```

<https://github.com/MikaelHoogen/home-assistant/blob/master/esphome/regnlogger-nimbus.yaml>

Denna fil är källan för:

- vad Nimbus faktiskt är avsedd att köra,
- ESPHome-framework,
- pin mode,
- inversion,
- debounce,
- MQTT-publicering,
- lokala räknare.

Vid granskningen 2026-07-17 innehöll filen rätt 8DI-8DO-modell, ESP-IDF, `GPIO4`, `input: true` och inversion, men ingen explicit pull-up.

### Hydromet-core referensimplementation

```text
MikaelHoogen/hydromet-core
└── deployments/sannesholma/nimbus/esphome.yaml
```

Denna fil är referens-/utvecklingsimplementation och får inte automatiskt behandlas som driftsatt firmware.

## 4. SMHI

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

## 5. Svenskt Vatten

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

## 6. MSB

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

## 7. Egna tekniska antaganden och designbeslut

Följande är designbeslut i detta projekt och inte externa källfakta:

- `logger_test` används permanent som scenariokälla.
- Netatmo cloud behandlas som egen 5-minuters intervallserie.
- TB4 är huvudvolymkälla men korta tidsfördelningar kvalitetsflaggas.
- Home Assistant prioriteras före Grafana som första presentationslager.
- Systemet ska vara modulärt och utbyggbart.
- Lokal IDF är ett långsiktigt mål, inte en tidig ersättning för SMHI/Dahlström.
- MSB2260 används som framtida scenario-/konsekvenslager, inte som ersättning för IDF-/mätkärnan.
- SVU 2019/Dahlström 2018 används som framtida klimatprediktorbaserad jämförelsemetod, inte som första normgivande IDF-kärna.
- Nimbus TB4 kopplas mellan `DI1` och `DGND`.
- Nimbus använder ingen extern ingångsmatning för TB4.
- GPIO4 ska ha en definierad vilonivå; intern pull-up är beslutad målkonfiguration.
- Aktiv driftkonfiguration och referensimplementation är separata källor och ska versionsspåras var för sig.
