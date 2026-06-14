# ADR-0003: Netatmo cloud behandlas som intervallserie

## Status

Accepted

## Bakgrund

Netatmo-data via moln/API kommer inte vara råa tipping-bucket-pulser i den aktuella lösningen. Den kommer in som aggregerad data, preliminärt i cirka 5-minutersintervall.

## Beslut

Netatmo cloud ska behandlas som egen intervallserie, inte som råpulstabell.

Föreslagen serie:

```text
netatmo_cloud
```

Föreslagen råtabell:

```text
rain_interval_observations
```

I hydromet core motsvarar detta i första hand:

```text
hydromet.interval_observations
```

## Konsekvenser

Fördelar:

- tydlig skillnad mellan råpuls och aggregerad mätning,
- Netatmo kan användas för jämförelse mot TB4,
- 15 min och längre varaktigheter kan bli intressanta,
- framtida Netatmo-råpuls kan läggas till separat.

Begränsningar:

- Netatmo cloud ska inte användas som primär källa för mycket korta intensitetstoppar,
- tidsupplösningen är grövre än råpuls,
- eventuella molnfördröjningar och API-luckor behöver kvalitetsflaggas.
