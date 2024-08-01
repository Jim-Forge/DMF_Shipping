import requests

def get_api_key(user_id, password):
    """
    Retrieves an API key from the specified endpoint by sending a POST request
    with user ID and password.

    Args:
        user_id (str): The user ID to authenticate.
        password (str): The password to authenticate.

    Returns:
        str: The API key if the request is successful, otherwise None.
    """
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
        response.raise_for_status()  # Raise an exception for non-2xx status codes
        api_key = response.text.strip()
        return api_key
    except requests.exceptions.RequestException as e:
        print(f"Error occurred: {e}")
        return None

# Example usage
user_id = "dmfintegrations@davincimfc.com"
password = "DavinC$2_2024"
api_key = get_api_key(user_id, password)
if api_key:
    print(f"API Key: {api_key}")
else:
    print("Failed to retrieve API key.")