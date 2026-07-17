# Begrepp

Status: Levande begreppslista

## Hydromet

Samlingsnamn för hydrologiska och meteorologiska observationer och analyser.

I detta projekt omfattar det exempelvis:

```text
väder
nederbörd
mark
nivå
flöde
vattenkvalitet
anläggningsrespons
systemhälsa
```

## Observationsserie

En tidsserie eller händelseserie från en viss källa, exempelvis `tb4_logger_ha`, `pond_1_level` eller `wind_station_1_speed`.

## Mätuppställning

Den fysiska och tekniska konfigurationen för en observationsserie under en viss tidsperiod.

## Punktobservation

Ett värde vid en tidpunkt, exempelvis nivå, temperatur eller vindhastighet.

## Intervallobservation

Ett värde som representerar ett tidsintervall, exempelvis regn under 5 minuter eller medelvind under 10 minuter.

## Händelseobservation

En diskret händelse, exempelvis tipping bucket-puls, regnstart, bräddning eller pumpstart.

## IDF

Intensity-Duration-Frequency. Samband mellan regnintensitet, varaktighet och återkomsttid.

## Varaktighet

Den tidsperiod som regnvolymen summeras över, till exempel 15 minuter, 60 minuter eller 720 minuter.

## Rullande fönster

Ett tidsfönster som kan sluta vid valfri tidpunkt. Exempel: senaste 15 minuter.

## Fast klockfönster

Ett tidsfönster som följer fasta klockintervall, exempelvis 12:00–12:15.

## Återkomsttid

Statistiskt mått på hur ofta en viss nivå i genomsnitt överskrids. En 100-årshändelse betyder ungefär 1 procents årlig sannolikhet för överskridande, inte att händelsen bara kan inträffa vart hundrade år.

## Återkomstklass

Intervallbaserad klassning, till exempel 5–10 år eller 10–20 år.

## Interpolerat återkomstestimat

Ett beräknat ungefärligt återkomstvärde mellan tabellerade trösklar, till exempel 7,2 år. Ska visas med försiktighet.

## Skyfallsdefinition

Definition av skyfall, separat från återkomsttid. I SMHI-sammanhang används ofta minst 50 mm på en timme eller minst 1 mm på en minut.

## TB4

KISTERS/HyQuest TB4, en sifonmatad tipping bucket-regnmätare. Den kan vara bra för totalvolym men mycket korta tidsfördelningar behöver tolkas försiktigt.

Nimbus använder varianten med 0,2 mm per vippning.

## Tipping bucket / vippmätare

Regnmätare där vatten samlas i en vippa som tippar vid en viss volym, exempelvis 0,1 eller 0,2 mm.

## Sifonmatad mätare

Mätare där vatten kan samlas/batchas i en sifon innan det når tipping bucket-mekanismen. Detta kan påverka råpulsernas tidsfördelning.

## Potentialfri kontakt

Elektrisk kontakt som själv inte tillför någon spänning. Den öppnar eller sluter en extern eller intern mätslinga.

KISTERS TB4:s reedutgång är en potentialfri kontakt.

## Reedkontakt

Magnetiskt manövrerad kontakt. I TB4 sluts kontakten kort när mekanismen tippar och magneten passerar reedkontakten.

## DI1

Digital ingång 1 på Waveshare-kortet. På modellen `ESP32-S3-POE-ETH-8DI-8DO` är DI1 internt bunden till `GPIO4`.

## DGND

Retur på Waveshare-kortets isolerade digitala fältsida.

För Nimbus ska TB4:s potentialfria kontakt sluta `DI1` mot `DGND`.

## DICOM / COM

Gemensam terminal för aktivt externt spänningsmatad digital ingång på den aktuella Waveshare-modellen.

Den används inte som retur för Nimbus potentialfria TB4-kontakt.

## ESP32-GND

Logikjord på ESP32-/processorsidan. Den är skild från den isolerade fältsidans `DGND` och ska inte användas som TB4-retur.

## Galvanisk isolation

Separation utan avsiktlig DC-ledande förbindelse mellan två kretsdelar. Energi eller signal kan ändå överföras via exempelvis transformator, isolerad DC/DC och optokopplare.

Galvanisk isolation innebär inte att fältsidan är omatad och innebär inte noll parasitisk kapacitans.

## Optokopplare

Komponent som överför ett logiskt tillstånd med ljus över en isolationsbarriär. Den används för att separera Waveshares fältingång från ESP32-sidan.

## Pull-up

Motstånd eller intern GPIO-funktion som håller en signal på logiskt hög nivå när ingen aktiv kretsdel drar den låg.

Nimbus målkonfiguration använder intern pull-up på `GPIO4`. Pull-up ligger på ESP32-sidan, matar inte TB4 och ersätter inte kopplingen `DI1–DGND`.

## Aktiv låg

Signal där det aktiva elektriska tillståndet är låg spänning eller logisk nolla.

Nimbus förväntade GPIO-polaritet är aktiv låg och presenteras som logiskt `ON` i ESPHome genom `inverted: true`.

## Flytande GPIO

Digital ingång utan tillräckligt definierad hög eller låg vilonivå. Den kan växla på grund av mycket små störningar och ge falska flankhändelser.

## Fältretur

Den terminal som sluter den avsedda fältslingan för en fysisk ingång. För Nimbus `DI1` är fältreturen `DGND`.

## Aktiv driftkonfiguration

Den konfigurationsfil som beskriver vad en fysisk enhet faktiskt är avsedd att köra i sin driftmiljö.

För Nimbus är detta:

```text
MikaelHoogen/home-assistant/esphome/regnlogger-nimbus.yaml
```

## Referensimplementation

Kod eller konfiguration som visar en avsedd implementation men inte automatiskt är den driftsatta versionen.

För Nimbus finns en sådan fil i `hydromet-core/deployments/sannesholma/nimbus/esphome.yaml`.

## Netatmo cloud

Data från befintlig Netatmo via moln/API. Behandlas som aggregerad intervallserie, inte råpulser.

## logger_test

Permanent test- och scenariokälla för att simulera regnpulser och testa hela kedjan.

## Årsmax

Årets högsta värde för en viss varaktighet. Används i extremvärdesstatistik.

## POT

Peak over Threshold. Metod där alla oberoende händelser över en vald tröskel används i analysen, inte bara årets största.

## GEV

Generalized Extreme Value. Extremvärdesfördelning som kan användas för årsmaxserier.

## GPD

Generalized Pareto Distribution. Fördelning som ofta används vid POT-analys.

## Klimatfaktor

Multiplikativ faktor som används för att justera regntrösklar med hänsyn till framtida klimat.

## Kvalitetsklass

Bedömning av hur robust ett värde är. Föreslagen skala:

```text
A = robust
B = användbar men med viss osäkerhet
C = indikativ
D = test/ej skarp
X = ogiltig eller ska ej användas
```

## Mätaröverensstämmelse

Jämförelse mellan flera mätserier, exempelvis TB4 och Netatmo cloud.

## Metodosäkerhet

Osäkerhet eller skillnad som uppstår när olika referensmetoder, exempelvis SMHI och Dahlström, ger olika tolkning.

## Varaktighetsprofil

En händelses maxvärden och klassning för flera varaktigheter, exempelvis 15, 30, 60, 120 och 360 minuter.

## Mest extrem varaktighet

Den varaktighet där händelsen är mest extrem relativt vald referensmetod.

## Effektobservation

Manuell observation av faktisk effekt på platsen, till exempel vatten i dike, stående vatten eller flöde över väg.
