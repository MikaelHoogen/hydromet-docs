# Designreview-checklista för regnlogger

Status: Kompletterande arkitekturstöd

Detta dokument kompletterar loggernivåerna och ska beskriva praktiska kontrollpunkter inför implementation.

## Nivå 1

En Nivå 1-logger ska ha:

- lokal monoton räknare
- retained state
- live-event per accepterad vippning
- tidstatus i payload
- status eller heartbeat
- kontroll av räknarhopp i mottagaren
- kvalitetsflagga vid osäker tidsfördelning
- dokumenterad filterstrategi för pulsingången

## Nivå 2

En Nivå 2-logger behöver dessutom:

- lokal eventjournal
- sekvensnummer
- bekräftelse från backend
- möjlighet att skicka ikapp events
- mottagare som tål dubbletter

## Princip

Osäker data är acceptabel om den flaggas.
