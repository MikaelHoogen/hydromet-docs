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

## Tipping bucket / vippmätare

Regnmätare där vatten samlas i en vippa som tippar vid en viss volym, exempelvis 0,1 eller 0,2 mm.

## Sifonmatad mätare

Mätare där vatten kan samlas/batchas i en sifon innan det når tipping bucket-mekanismen. Detta kan påverka råpulsernas tidsfördelning.

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
