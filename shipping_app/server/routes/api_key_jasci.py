import requests

def get_api_key(user_id, password):
    url = "https://uat-api.jasci.net/JasciRestApi/V2/apiKey"
    payload = {
        "userId": user_id,
        "password": password
    }
    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        json_response = response.json()
        return json_response.get("API-KEY")
    except requests.exceptions.RequestException as e:
        print(f"Error occurred: {e}")
        return None

# Example usage
# user_id = "dmfintegrations@davincimfc.com"
# password = "DavinC$2_2024"
# api_key = get_api_key(user_id, password)
# if api_key:
#     print(f"API Key: {api_key}")
# else:
#     print("Failed to retrieve API key.")