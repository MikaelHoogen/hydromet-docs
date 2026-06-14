# Beslutslogg

Detta dokument sammanfattar viktiga arkitekturbeslut. Detaljerade beslut dokumenteras som ADR i mappen `adr/`.

## Accepterade beslut

| ID | Beslut | Status |
|---|---|---|
| ADR-0001 | Rådata skrivs aldrig över | Accepted |
| ADR-0002 | `logger_test` är permanent scenariokälla | Accepted |
| ADR-0003 | Netatmo cloud behandlas som intervallserie | Accepted |
| ADR-0004 | Ingen framåtextrapolerande regnvarning | Accepted |
| ADR-0005 | Lokal IDF är ett långsiktigt mål | Accepted |
| ADR-0006 | Asymmetriska hälsokontroller mellan TB4 och Netatmo | Accepted |
| ADR-0007 | Klimatprediktorbaserad IDF är en framtida jämförelsemetod | Accepted |
| ADR-0008 | Hydromet core byggs före regnmodul | Accepted |

## Övriga inriktningsbeslut

### Home Assistant är primär presentation

Home Assistant ska vara vardagsgränssnittet. Grafana används senare för djupanalys.

### Både SMHI och Dahlström ska stödjas

Systemet ska stödja parallell klassning mot SMHI/Klimatologi 47 och Dahlström/Svenskt Vatten.

### Klimatjusterade trösklar ska finnas från början

Systemet ska kunna visa både klassning mot dagens trösklar och mot klimatjusterade trösklar.

### Både klass och interpolerat återkomstestimat ska finnas

Återkomstklass är primär visning. Interpolerat estimat är avancerad/sekundär visning.

### Regnhändelser byggs från början

Händelser är en central analysprodukt och ska inte vänta till senare.

### Systemet ska vara modulärt

Nya idéer ska kunna läggas till som moduler, vyer eller generiska analysresultat utan att rådatamodellen ändras.

### TB4:s korttidsvärden ska kvalitetsflaggas dynamiskt

TB4 är sifonmatad. Korta tidsfördelningar ska inte automatiskt betraktas som osäkra, utan kvalitetsklassas utifrån puls- och händelsemönster. Vid intensivt sammanhängande regn kan tidsstämplarna vara relativt robusta. Vid händelsestart efter uppehåll, lågintensiva regn och täta startpulser kan restvolym eller tidsförskjutning behöva flaggas.

### 5 minuter är diagnostik/nice-to-have

5 minuter får finnas i systemet men ska inte vara bärande återkomstklass för TB4.

### Officiella varaktigheter

```text
15, 30, 45, 60, 120, 360, 720, 1440 minuter
```

### Skyfallsdefinition hålls separat från återkomsttid

Skyfallsdefinition och återkomstklass är två olika saker och ska visas separat.

### Mätarkedjans hälsa är en kärnfunktion

Systemet ska övervaka heartbeat, MQTT, AppDaemon, databas, Netatmo cloud och jämförelser mellan mätare. Det ska larma på förlorade livstecken först och därefter på misstänkta mätaravvikelser.

### Netatmo och TB4 ska användas som kontroll av varandra

Systemet ska ha asymmetriska kontroller:

```text
Netatmo > 0,4 mm + TB4 online + 0 TB4-pulser
→ misstänkt TB4-avvikelse

TB4 >= 1,0 mm + Netatmo cloud OK + Netatmo 0 mm
→ misstänkt Netatmo-/jämförelseavvikelse
```

Dessa ska formuleras som misstänkta avvikelser, inte absoluta fel.

### Klimatprediktorbaserad IDF ska vara framtida jämförelsemetod

SVU 2019/Dahlström 2018 ska finnas i arkitekturen som framtida klimatprediktorbaserad jämförelsemetod, men inte ersätta den första IDF-kärnan.

Första IDF-kärnan är fortsatt:

```text
SMHI_Klimatologi_47
Dahlstrom_2010
klimatjusterade trösklar
```

Framtida jämförelsemetod:

```text
climate_predictor_idf
Dahlstrom_2018
scenario/RCP/tidsperiod
plats-/gridbaserade klimatprediktorer
```
