# Verifiering av Nimbus DI1-ingång

Status: Obligatorisk bänkprocedur före fältdrift

## 1. Syfte

Denna procedur verifierar hela signalkedjan:

```text
KISTERS TB4
→ DI1–DGND på Waveshares isolerade fältsida
→ optokopplare
→ GPIO4
→ ESPHome
→ lokal pulsräkning
```

På den fysiska plinten är `DGND` märkt `GND` i gruppen **Digital Inputs**. `DICOM` är märkt `COM`. Dessa plinttexter får inte blandas ihop med ESP32-logikjord.

Testet ska ersätta lösa kabel-, finger- och COM-tester som inte ger ett kontrollerat elektriskt tillstånd.

## 2. Säkerhetsgräns

Den normala TB4-verifieringen använder kortets interna isolerade terminalmatning.

Anslut inte:

```text
extern spänning till TB4-slingan
DI1 till DICOM/COM som dry-contact-test
DICOM/COM direkt till DGND
DGND till ESP32-GND
```

Resistans och kontinuitet mäts endast när enheten är spänningslös.

## 3. Förutsättningar

Verifiera före test:

```yaml
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do
physical_input: DI1
field_return: DGND
hardware_binding: GPIO4
sensor_model: KISTERS TB4
mm_per_tip: 0.2
```

Målkonfiguration:

```yaml
pin:
  number: GPIO4
  mode:
    input: true
    pullup: true
  inverted: true
```

Firmwareändring och dokumentation är separata åtgärder. Kör inte slutligt acceptanstest förrän den konfiguration som faktiskt flashats har verifierats mot den aktiva Home Assistant-filen.

## 4. Test A – TB4 separat

Koppla bort TB4 helt från loggern.

Mät kontinuitet mellan TB4:s två valda kontaktledare medan mekanismen vippas försiktigt.

Förväntat:

```text
vila       → öppen kontakt
vippning   → kort kontaktslutning
```

Bekräfta att rätt reedutgång och rätt ledarpar används. TB4 kan ha dubbel reedutgång.

## 5. Test B – öppen loggeringång

Koppla bort all fältkabel från `DI1` och den fysiska `GND`-plinten under **Digital Inputs**.

Starta loggern och observera:

- fysisk ingångsstatus,
- `raw_pulse_total`,
- `pulse_total`,
- `ignored_pulse_total`,
- DI1-indikator om den finns tillgänglig.

Förväntat:

```text
ingång = OFF
räknare = oförändrade
inga spontana pulser
```

Låt testet pågå minst fem minuter vid första verifieringen.

## 6. Test C – kontrollerad bygel DI1–DGND

Använd en kort, isolerad kabelbit som bygel mellan `DI1` och den fysiska `GND`-plinten i gruppen **Digital Inputs**.

```text
DI1 o────────o GND
               └─ DGND i dokumentationen
```

### När bygeln sätts dit

Förväntat:

```text
fysisk ingång → ON
raw_pulse_total → +1
pulse_total → +1
```

### När bygeln tas bort

Förväntat:

```text
fysisk ingång → OFF
pulse_total → ingen ytterligare ökning
```

Upprepa fem gånger med tydliga pauser. Varje slutning ska ge exakt en accepterad puls.

## 7. Test D – fel terminal som negativ kontroll

En kort bygel mellan `DI1` och den fysiska `COM`-plinten (`DICOM` i diagrammet) är inte den korrekta passiva kopplingen och ska inte användas som normal testmetod.

Om en säker negativ kontroll ändå genomförs av kvalificerad person ska resultatet dokumenteras som just negativ kontroll, inte som dry-contact-verifiering. Kortslut aldrig `COM/DICOM` mot `GND/DGND`.

## 8. Test E – TB4 inkopplad

Anslut:

```text
TB4 ledare 1 → DI1
TB4 ledare 2 → GND under Digital Inputs
                └─ DGND i dokumentationen
```

Gör tio långsamma manuella vippningar.

Acceptans:

```text
raw_pulse_total ökar med minst 10
pulse_total ökar exakt med 10
rain_total_mm ökar med 2,0 mm
```

Kontaktstuds kan göra att `raw_pulse_total` ökar mer än tio, men `pulse_total` ska öka exakt tio gånger efter debounce.

## 9. Test F – 100-vippningstest

Nollställ eller anteckna startvärden.

Genomför exakt 100 kontrollerade vippningar med tillräckligt mellanrum för att inte träffa debouncegränsen.

Acceptans:

```text
pulse_total delta = 100
rain_total_mm delta = 20,0 mm
```

Avvikelse innebär att installationen inte godkänns för fältdrift.

## 10. Test G – störning och flytande ledning

Detta test görs endast för att förstå störkänslighet och lokalisera fel. Det är inte ett funktions- eller acceptanstest.

### Ingen kabel

Förväntat: stabilt `OFF`, inga pulser.

### Lös ledning på DI1 eller GND/DGND

Ingen normativ godkänd/underkänd förväntan sätts för en lång, öppen fältledning. En sådan ledning fungerar som antenn och kan koppla störning till den isolerade ingångssidan. Intern pull-up stabiliserar GPIO4 efter optokopplaren men kan inte garantera att optokopplaringången aldrig aktiveras av stark fältstörning.

Beröring med finger är därför inte ett giltigt pulstest och ingår inte i acceptanskriterierna.

### Tolkning med indikator

| DI1-indikator | GPIO4/ESPHome | Trolig störplats |
|---|---|---|
| Blinkar | Växlar | Fältsidan eller optokopplaringången aktiveras |
| Still | Växlar | GPIO-/pull-up-/logiksidesproblem |
| Blinkar | Växlar inte | Optokopplarutgång, fel GPIO eller firmwareproblem |
| Still | Stabil | Ingen aktivering, normalt viloläge |

Indikatorns betydelse ska först kalibreras med det kontrollerade `DI1–GND/DGND`-testet.

## 11. Test H – pull-up före och efter

För att isolera pull-up-effekten kan två firmwareversioner jämföras med all fältkabel bortkopplad.

### Variant 1

```yaml
mode:
  input: true
```

### Variant 2

```yaml
mode:
  input: true
  pullup: true
```

Om variant 1 ger instabil nivå eller falska pulser medan variant 2 är stabil visar testet att den interna pull-up-funktionen behövs för en definierad vilonivå i den aktuella implementationen.

Testet ska inte användas som enda underlag för att uttala sig om kortets fullständiga interna schema eller om störningar på fältsidan.

## 12. Valfria multimetermätningar

### Kortet spänningslöst

Mät kontinuitet mellan:

```text
GND under Digital Inputs / DGND ↔ ESP32-GND
COM / DICOM                     ↔ ESP32-GND
```

Förväntat: ingen stabil lågohmig förbindelse.

### Kortet spänningssatt

Mät i första hand differentialt på fältsidan:

```text
COM/DICOM mot GND/DGND
DI1 mot GND/DGND
```

Waveshare anger intern isolerad terminalmatning. Exakt spänning och loopström ska dokumenteras som mätresultat, inte antas utan mätning.

Mät aldrig ström genom att lägga amperemetern direkt mellan `COM/DICOM` och `GND/DGND`. Strömmätning görs endast i serie i en kontrollerad ingångsslinga.

## 13. Driftmatris

Verifiera vid behov:

| Driftfall | Förväntat resultat |
|---|---|
| PoE utan USB | Stabil ingång |
| PoE och Ethernettrafik | Stabil ingång |
| PoE + USB ansluten | Stabil ingång |
| MQTT frånkopplad | Lokal räknare fortsätter |
| Home Assistant/API frånkopplat | Lokal räknare fortsätter |
| Logger reboot | Boot och räknarpersistens hanteras enligt Nivå 1 |

## 14. Testprotokoll

```yaml
test_date: YYYY-MM-DD
operator: <namn>
site_id: sannesholma
logger_id: nimbus
hardware_model: waveshare_esp32_s3_poe_eth_8di_8do
hardware_revision: <om känd>
sensor_id: tb4_0p2
active_config_repo: MikaelHoogen/home-assistant
active_config_path: esphome/regnlogger-nimbus.yaml
active_git_commit: <sha>
firmware_version: <version>
esphome_version: <version>
framework: esp-idf
pin_mode_verified:
  input: true
  pullup: true
  inverted: true
results:
  open_input_stable: true | false
  jumper_cycles_expected: 5
  jumper_cycles_counted: <antal>
  ten_tips_counted: <antal>
  hundred_tips_counted: <antal>
  hundred_tips_rain_mm: <värde>
  spontaneous_pulses_with_no_cable: <antal>
  loose_wire_observation: <text, ej acceptanskriterium>
acceptance: passed | failed
notes: <text>
```

## 15. Godkännanderegel

```text
Ingen kontrollerad DI1–GND/DGND-funktion
→ ingen godkänd TB4-installation.

Ingen stabil vilonivå utan fältkabel eller med korrekt ansluten TB4 i vila
→ ingen godkänd Nivå 1-ingång.

100 vippningar ≠ 100 accepterade pulser
→ ingen fältdrift som observationskälla.
```
