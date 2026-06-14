# Hydromet Docs

Levande dokumentation för en modulär hydromet-plattform byggd kring observationer av väder, vatten, mark och anläggningsrespons.

Projektet började som ett lokalt regn- och skyfallsobservatorium, men dokumentationen har lyfts ut från Home Assistant-repot eftersom målbilden är bredare än en enskild implementation.

## Grundidé

```text
hydromet core
→ generella observationsserier och råobservationer
→ systemhälsa
→ regnmodul
→ nivå/flöde/mark/vind/vattenkvalitet senare
→ analys, tolkning och presentation
```

## Relation till Home Assistant-repot

`MikaelHoogen/home-assistant` är implementation och driftmiljö.

`MikaelHoogen/hydromet-docs` är metod, arkitektur, datamodell, källor och långsiktig dokumentation.

## Dokumentation

Dokumentationen är avsedd att byggas med MkDocs/Material.

Startpunkt:

```text
docs/index.md
```
