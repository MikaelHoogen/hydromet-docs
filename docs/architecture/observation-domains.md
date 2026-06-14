# Framtida observationsdomäner

Status: Arkitektur / målbild

## 1. Grundprincip

Hydromet-plattformen ska inte bara kunna lägga till nya sensorer. Den ska också kunna lägga till nya klasser av data.

Designregel:

```text
Nya dataklasser ska kunna dockas på genom observationsserier, observationstyper, metadata och modulär analys — inte genom ny grundarkitektur.
```

Hydromet ska vara brett nog för väder, vatten, mark och anläggningsrespons, men inte bli en generell dataplattform för allt mellan himmel och jord.

## 2. Domänkarta

```text
1. Atmosfär
   - vind
   - temperatur
   - luftfuktighet
   - lufttryck
   - solinstrålning

2. Nederbörd
   - regnmängd
   - regnintensitet
   - regndetektion
   - snö / snösmältning

3. Mark
   - markfukt
   - marktemperatur
   - förregnsförhållanden

4. Hydraulik
   - nivå i damm/brunn/dike
   - flöde i utlopp/inlopp
   - pumpstatus
   - bräddning
   - tömningstid

5. Vattenkvalitet
   - temperatur i vatten
   - konduktivitet
   - turbiditet
   - eventuellt pH/syre senare
```

Domänkartan är inte en kravlista för första versionen. Den är en arkitektonisk ram för att datamodellen ska hålla när nya dataklasser läggs till.

## 3. Atmosfär / meteorologi

Exempel på dataklasser:

```text
vindhastighet
vindriktning
vindby
lufttemperatur
relativ luftfuktighet
barometertryck / lufttryck
solinstrålning
globalstrålning
molnighet, om källa finns
```

Typiska observationstyper:

```text
point_observations
interval_observations
```

Möjlig användning:

```text
förklara avdunstning och upptorkning
förstå vindpåverkan på nederbördsmätning
koppla väderläge till regnhändelser
bedöma energibalans och mark-/vattenrespons
```

## 4. Nederbörd

Exempel på dataklasser:

```text
regnpuls från tipping bucket
regnintervall från moln/API
regnmängd
regnintensitet
regndetektion / regn pågår
regndroppshändelser
snö
snödjup
snösmältning
hagel, om källa finns
```

Typiska observationstyper:

```text
event_observations
interval_observations
point_observations
```

Möjlig användning:

```text
lokal regnhistorik
varaktighetsanalys
IDF-jämförelse
återkomstklassning
regndetektion som tidsreferens för faktisk regnaktivitet
jämförelse mellan mätare och moln/API
```

## 5. Mark

Exempel på dataklasser:

```text
markfukt
marktemperatur
jordtemperatur
markvattenpotential
förregnsförhållanden
frost/tjäle, om källa finns
```

Möjlig användning:

```text
förklara avrinningsrespons
skilja torr mark från mättad mark
förstå säsongseffekter
bedöma infiltration före regn
koppla förregnsförhållanden till nivå- och flödesrespons
```

## 6. Hydraulik

Exempel på dataklasser:

```text
nivå i damm
nivå i brunn
nivå i dike
flöde i inlopp
flöde i utlopp
flöde från brunn
ledningstryck
vattenföring i ledning
uppdämning
bakvatten
bräddning
överfall
pumpstatus
pumpgropnivå
uppehållstid
tömningstid
```

Möjlig användning:

```text
koppla regn till nivårespons
koppla regn till flödesrespons
identifiera uppdämning
förstå fördröjning mellan regn och flöde
jämföra dammrespons och brunnsrespons
beräkna tömningstid efter regn
identifiera bräddning och överfall
```

## 7. Vattenkvalitet

Exempel på dataklasser:

```text
temperatur i vatten
konduktivitet
turbiditet
pH, eventuellt senare
löst syre, eventuellt senare
salthalt, eventuellt senare
```

Möjlig användning:

```text
förstå first flush
koppla grumlighet till regnintensitet
följa temperatur i damm eller utlopp
identifiera förändringar vid inflöde, bräddning eller tömning
```

## 8. Systemhälsa och driftstatus

Exempel:

```text
logger online/offline
heartbeat
batterispänning
signalstyrka
MQTT-status
AppDaemon-ingest
TimescaleDB-status
pump går / stopp
pumpfel
ventilläge
luckläge
strömavbrott
underhållshändelse
rensning
```

Detta är viktigt för att kunna tolka data. En nivå som inte sjunker kan bero på hydraulik, men också på pumpfel, igensättning, stängd ventil eller förlorad mätkedja.

## 9. Externa referensdata och manuella observationer

Externa referensdata kan vara:

```text
SMHI-observationer
SMHI-prognoser
radardata
Netatmo cloud
klimatscenarier
modellregn
IDF-trösklar
```

Manuella observationer kan vara:

```text
vatten stod på markyta
brunn dämd
flödet gick över gångväg
inlopp igensatt
rensning utförd
foto taget
upplevd regnstart eller regnslut
```

Princip:

```text
Externa referensdata och manuella observationer ska klassas tydligt och inte blandas ihop med lokala primärmätningar.
```
