# ADR-0010: Regnloggernivåer och mätintegritet

Status: Antagen

Datum: 2026-06-30

## Kontext

RainLens/Hydromet använder regnloggers för att samla in pulser från tipping bucket-regnmätare. Dessa pulser ligger till grund för ackumulerad nederbörd, intensitet, blockregn, IDF-analys, återkomsttider och långsiktig statistik.

Den nuvarande tekniska riktningen bygger på ESPHome, MQTT, Home Assistant/AppDaemon och senare Hydromet/RainLens-ingest. Detta är en smidig och kraftfull prototypmiljö, men den innebär inte automatiskt produktionssäker mätintegritet.

Ett kritiskt problem identifierades: om loggern endast publicerar varje puls som ett flyktigt MQTT-event kan pulser förloras när MQTT-broker, AppDaemon, Home Assistant eller backend är nere. Retained MQTT-meddelanden löser senaste state, men inte en hel händelseserie. Ackumulerad mängd kan räddas genom en monoton räknare, men exakt tidsfördelning kräver eventlogg eller buffert.

## Beslut

RainLens/Hydromet ska använda en tydlig nivåmodell för regnloggers:

```text
Nivå 0 – Enkel testlogger
Nivå 1 – Robust prototyp / fältpilot
Nivå 2 – Produktionslogger
Nivå 3 – Mätarklassad / industriell logger
```

Den nuvarande ESPHome + MQTT + Home Assistant/AppDaemon-lösningen ska betraktas som Nivå 1: robust prototyp / fältpilot.

Den ska inte dokumenteras eller behandlas som skottsäker produktionslogger.

Följande princip gäller:

```text
En vippning får aldrig bara existera som ett flyktigt MQTT-event.
```

Minimikrav för Nivå 1:

- Loggern håller lokal monoton `tip_count` eller `pulse_total`.
- Räknarställningen publiceras som retained MQTT state.
- Varje accepterad vippning publiceras även som live-event när mottagande system är tillgängligt.
- Mottagande system ska jämföra eventflöde mot räknarställning.
- Hopp i räknarställning ska användas för att upptäcka missade events.
- Perioder där exakt tidsfördelning inte kan garanteras ska flaggas som osäkra.
- Home Assistant/AppDaemon ska inte betraktas som primär sanning för rå pulsräkning.
- MQTT ska betraktas som transport, inte som system of record.

Nivå 2 kräver lokal eventjournal eller buffert, sekvensnummer, backend-ack och replay av missade events.

## Konsekvenser

### Positiva konsekvenser

- Vi undviker att överdriva robustheten i nuvarande prototypkedja.
- Nuvarande ESPHome-spår kan fortsätta, men med rätt ambitionsnivå.
- Logger-YAML och AppDaemon-logik får tydligare krav.
- Framtida produktionslogger kan byggas utan att ändra den grundläggande identitets- och topicmodellen.
- Dataosäkerhet blir synlig i stället för tyst.

### Begränsningar

- Nivå 1 garanterar inte exakt puls-tidsserie över alla avbrott.
- Ackumulerad nederbörd kan återhämtas via räknarställning, men tidsfördelning kan behöva flaggas som osäker.
- Ren ESPHome-YAML är inte tillräcklig för Nivå 2.
- För Nivå 2 eller 3 krävs sannolikt egen komponent, egen firmware, extern icke-flyktig lagring eller industriell pulsräknare.

## Implementation i närtid

Den nuvarande PoE/Ethernet-baserade loggern ska byggas som Nivå 1.

Det innebär:

```text
ESPHome
→ lokal pulse_total
→ retained MQTT state
→ live tip-event
→ AppDaemon/Hydromet ingest
→ delta-detektering
→ osäkerhetsflaggor vid luckor
```

Följande bör ingå i kommande ESPHome/AppDaemon-arbete:

- persistent eller återställbar pulsräknare
- retained state-topic
- tip-event-topic
- status/heartbeat-topic
- boot count eller boot id
- tidstatus i payload
- diagnostik för senast accepterad puls
- AppDaemon-logik för att upptäcka hopp i `pulse_total`
- kvalitetsflagga för perioder där tidsfördelning saknas

## Vägen vidare

För Nivå 2 bör RainLens/Hydromet utreda:

- ESPHome external component för pulsloggning
- lokal ringbuffer/eventjournal
- sekvensnummer per event
- backend-ack-topic
- batch/replay av missade events
- extern FRAM eller annan icke-flyktig lagring
- idempotent ingest i backend

## Relaterade dokument

- `docs/architecture/logger-reliability-levels.md`
- `docs/architecture/mqtt-message-contract.md`
- `docs/architecture/system-health.md`
