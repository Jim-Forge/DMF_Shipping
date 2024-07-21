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
        response.raise_for_status()
        
        result = response.json()
        
        message = "The address is valid." if result.get('valid') else "The address is not valid."
        
        details = result.get('details', [])
        if details:
            error_messages = [f"{detail['errorCode']}: {detail['errorDescription']}" for detail in details]
            message += f" Details: {'; '.join(error_messages)}"
        
        candidate = result.get('candidate')
        if candidate:
            message += f"\nCandidate: {json.dumps(candidate, indent=2)}"
        
        return message
    
    except requests.exceptions.RequestException as e:
        return f"An error occurred: {str(e)}"
