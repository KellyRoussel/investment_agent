import os

import requests

OPENFIGI_URL = "https://api.openfigi.com/v3/mapping"
class OpenFigiClient:
    @staticmethod
    def isin_to_ticker(isin: str) -> str:
        headers = {
        "Content-Type": "application/json",
        "X-OPENFIGI-APIKEY": os.getenv("OPENFIGI_API_KEY", ""),
        }

        payload = [{
            "idType": "ID_ISIN",
            "idValue": isin,
        }]

        response = requests.post(OPENFIGI_URL, json=payload, headers=headers)
        response.raise_for_status()

        data = response.json()[0].get("data", [])
        if not data:
            raise ValueError(f"No instrument found for ISIN {isin}")

        # On prend le premier résultat (suffisant pour Trade Republic)
        instrument = data[0]

        
        return instrument.get("ticker","")