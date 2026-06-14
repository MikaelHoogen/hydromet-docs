# ADR-0001: Rådata skrivs aldrig över

Status: Accepted

## Kontext

Hydromet-plattformen ska kunna reanalysera historik när metoder, trösklar, mätuppställningar eller analysmoduler förändras.

Om rådata skrivs över går det inte att återskapa eller kontrollera tidigare analyser.

## Beslut

Rådata ska aldrig skrivas över.

Korrigeringar, kvalitetsflaggor, metadata och tolkningar ska lagras separat eller som nya versioner.

## Konsekvenser

```text
råa payloads sparas
mottagningstid sparas
händelsetid sparas separat
mätuppställning versioneras
analysresultat kan räknas om
historik kan reklassas
```

## Designregel

```text
Rådata är helig.
Analys är omräkningsbar.
Tolkning är versionerad.
```
