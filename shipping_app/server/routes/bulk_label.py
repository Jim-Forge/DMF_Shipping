import requests
import json
import base64

API_KEY = 'your_api_key_here'  # Replace with your actual API key

def create_bulk_shipment_labels(shipment_requests):
    url = 'https://api.shipium.com/api/v1/shipment/bulkprocessing/labels'
    
    request_body = {
        "options": {
            "currencyCode": "usd",
            "fulfillmentContext": "test-tenant",
            "tenantId": "test-tenant",
            "includeFullShipmentResponses": False
        },
        "shipmentRequests": shipment_requests
    }

    headers = {
        'Authorization': f'Basic {base64.b64encode((API_KEY + ":").encode()).decode()}',
        'Content-Type': 'application/json'
    }

    response = requests.post(url, headers=headers, data=json.dumps(request_body))

    if response.status_code != 200:
        raise Exception(f"Request failed with status code {response.status_code}: {response.text}")

    return response.json()

# Usage example:
# shipment_requests = [...]  # List of shipment request objects
# result = create_bulk_shipment_labels(shipment_requests)
# print(result)