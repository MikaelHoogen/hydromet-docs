# ADR-0006: Asymmetriska hälsokontroller mellan TB4 och Netatmo

## Status

Accepted

## Bakgrund

Systemet ska kunna använda flera mätserier för att upptäcka möjliga fel i mätkedjan. TB4 och Netatmo cloud har olika mätprincip, upplösning och rapporteringsväg.

En särskilt användbar kontroll är när en mätare registrerar regn men den andra är tyst.

## Beslut

Systemet ska ha jämförelsebaserade hälsokontroller åt båda håll:

```text
Netatmo registrerar regn men TB4 ger inga pulser.
TB4 registrerar regn men Netatmo cloud visar 0 mm.
```

Kontrollerna ska vara asymmetriska.

## Netatmo → TB4

Om Netatmo cloud registrerar mer än cirka 0,4 mm under ett sammanhängande regnfönster, men TB4 inte registrerar någon puls inom rimlig tidsmarginal och TB4-loggern är online, ska systemet flagga möjlig TB4-avvikelse.

Alert:

```text
tb4_expected_tip_missing
```

Motiv:

```text
Netatmo > 0,4 mm + TB4 online + 0 TB4-pulser
= TB4 borde normalt ha visat minst ett livstecken.
```

## TB4 → Netatmo

Om TB4 registrerar tydlig nederbörd, men Netatmo cloud är uppdaterat och ändå visar 0 mm, ska systemet flagga möjlig Netatmo- eller jämförelseavvikelse.

Alert:

```text
netatmo_expected_rain_missing
```

Föreslagna nivåer:

```text
TB4 >= 0,2 mm och Netatmo = 0
→ ingen notis, bara diagnostisk skillnad

TB4 >= 0,6 mm och Netatmo = 0
→ mild avvikelse / diagnostik

TB4 >= 1,0 mm och Netatmo = 0
→ varning

TB4 >= 2,0 mm och Netatmo = 0
→ stark varning, om Netatmo cloud-status är OK
```

## Konsekvenser

Fördelar:

- systemet kan upptäcka misstänkta mätar- eller kedjeproblem,
- TB4 och Netatmo används som kontroll av varandra,
- larmen blir mer intelligenta än bara “inga pulser”,
- asymmetriska trösklar minskar risken för falsklarm.

Begränsningar:

- mätarjämförelser är inte absoluta bevis på fel,
- lokal variation, placering, vind, Netatmo-upplösning, molnfördröjning och avrundning kan påverka,
- därför ska larmen formuleras som misstänkta avvikelser.

## Princip

```text
Larma först på förlorade livstecken.
Jämför därefter mätserier.
Formulera mätarjämförelser som misstänkta avvikelser, inte absoluta fel.
```
