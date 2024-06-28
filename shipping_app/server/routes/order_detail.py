import requests
import json

def get_sales_order(api_key, sales_order_id, company, fulfillment_center):
    try:
        headers = {
            # "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "API-KEY-X": api_key,
        }

        params = {
            "salesOrderId": sales_order_id,
            "company": company,
            "fulfillmentCenter": fulfillment_center
        }

        response = requests.get("https://uat-api.jasci.net/JasciRestApi/V2/salesOrder", headers=headers, params=params)
        response.raise_for_status()

        data = response.json()

        # Extract required details
        required_details = {
            "salesOrderId": data["data"]["salesOrderId"],
            "customerId": data["data"]["customerId"],
            "firstName": data["data"]["firstName"],
            "lastName": data["data"]["lastName"],
            "addressLine1": data["data"]["addressLine1"],
            "city": data["data"]["city"],
            "stateCode": data["data"]["stateCode"],
            "countryCode": data["data"]["countryCode"],
            "zipCode": data["data"]["zipCode"],
            "details": [
                {
                    "lineNumber": item["lineNumber"],
                    "product": item["product"],
                    "unitOfMeasureQty": item["unitOfMeasureQty"],
                    "unitOfMeasureCode": item["unitOfMeasureCode"]
                }
                for item in data["data"]["details"]
            ]
        }

        return required_details
    except requests.exceptions.RequestException as e:
        print(f"Error occurred: {e}")
        return None

# Example usage
api_key = "ZG1maW50ZWdyYXRpb25zQGRhdmluY2ltZmMuY29tfERhdmluQyQxXzIwMjQ="
sales_order_id = "MR-TEST_SHIP_4"
company = "Davinci Micro Fulfillment"
fulfillment_center = "Bound Brook"
required_details = get_sales_order(api_key, sales_order_id, company, fulfillment_center)
if required_details:
    print(f"Required Details: {required_details}")
else:
    print("Failed to retrieve required details.")