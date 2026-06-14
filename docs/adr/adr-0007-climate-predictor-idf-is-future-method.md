# ADR-0007: Klimatprediktorbaserad IDF är en framtida jämförelsemetod

## Status

Accepted

## Bakgrund

SVU-rapporten *Regnintensitet i ett förändrat klimat i Sverige med data tillgängliga för användare* beskriver en dynamisk platsbaserad metodmiljö där användaren kan undersöka klimatprediktorer, klimatfaktorer, beräkningsregn och återkomsttid för egna regndata.

Rapporten är kopplad till utvecklingen från Dahlström 2010 via senare metodsteg till Dahlström 2018.

Samtidigt finns befintliga rekommendationer i Svenskt Vatten M148 om att tills vidare använda Dahlström 2010 för dimensionering, och systemets första IDF-kärna ska även stödja SMHI/Klimatologi 47.

## Beslut

Klimatprediktorbaserad IDF och Dahlström 2018 ska finnas i arkitekturen som framtida/experimentell jämförelsemetod, inte som primär metod i MVP.

Föreslagen modul:

```text
climate_predictor_idf
```

Alternativt mer specifikt:

```text
dahlstrom_2018_climate_predictor_context
```

## Konsekvenser

Fördelar:

- systemet kan senare stödja mer avancerad platsbaserad klimatjämförelse,
- klimatfaktorer, beräkningsregn, scenario, RCP och tidsperiod kan hanteras spårbart,
- uppmätta lokala händelser kan jämföras mot fler metodfamiljer,
- modulen passar väl ihop med framtida lokal IDF.

Begränsningar:

- metoden ska inte byggas i första MVP,
- resultaten ska inte presenteras som exakt framtida sanning,
- den ska inte automatiskt ersätta SMHI/Klimatologi 47 eller Dahlström 2010,
- alla resultat måste bära metodversion, plats, scenario, tidsperiod och kvalitetsklass.

## Princip

```text
Primär IDF-kärna först.
Klimatprediktorbaserad IDF senare.
Allt ska vara jämförbart, versionerat och spårbart.
```
