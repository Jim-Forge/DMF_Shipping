import requests
import base64
import json

def validate_address(shipium_api_key, address):
    url = "https://api.shipium.com/api/v1/address/validate"
    
    headers = {
        'Authorization': f'Basic {base64.b64encode((shipium_api_key + ":").encode()).decode()}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        "address": address,
        "ignoreSecondaryAddressMismatch": "false",
        "includeCandidate": "true"
    }
    
    try:
        response = requests.post(url, headers=headers, data=json.dumps(payload))
        response.raise_for_status()  # Raises a HTTPError if the status is 4xx, 5xx
        
        result = response.json()
        
        if result.get('valid'):
            return "The address is valid."
        else:
            details = result.get('details', [])
            if details:
                error_messages = [f"{detail['errorCode']}: {detail['errorDescription']}" for detail in details]
                return f"The address is not valid. Details: {'; '.join(error_messages)}"
            else:
                return "The address is not valid."
    
    except requests.exceptions.RequestException as e:
        return f"An error occurred: {str(e)}"
