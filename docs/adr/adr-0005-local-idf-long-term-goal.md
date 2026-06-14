# ADR-0005: Lokal IDF är ett långsiktigt mål

## Status

Accepted

## Bakgrund

Systemet ska inte bara klassificera enskilda regnhändelser mot externa underlag. På lång sikt, exempelvis efter flera decennier av mätning, ska den lokala serien kunna användas för egen extremvärdesanalys och egna lokala IDF-samband.

## Beslut

Arkitekturen ska från början ta höjd för lokal IDF på lång sikt.

Det innebär att systemet ska stödja:

```text
långsiktigt sparad rådata
versionerade mätuppställningar
datatäckningsmått
årsmax per varaktighet
POT-kandidater
extremvärdesmodeller
lokala IDF-estimat
reklassning av historik
```

## Konsekvenser

Fördelar:

- data som behövs om 10, 20 eller 40 år börjar samlas från dag ett,
- mätarbyten och datagap kan hanteras spårbart,
- lokal statistik kan jämföras mot SMHI och Dahlström i framtiden.

Begränsningar:

- lokal IDF ska inte ses som ersättning för SMHI/Dahlström tidigt,
- få års data ger stor osäkerhet,
- kompletthet och homogenitet i serien blir avgörande.

## Princip

```text
Operativt nu.
Händelsearkiv över tid.
Lokal IDF först på lång sikt.
```
