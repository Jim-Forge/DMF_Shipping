import requests
import sys
import json
import logging
import os
from typing import Dict, Any, List

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import_errors = []

try:
    from routes.product_detail import get_product_details
    # logging.debug("Successfully imported get_product_details")
except ImportError as e:
    logging.error(f"Error importing get_product_details: {str(e)}")
    import_errors.append(("get_product_details", str(e)))

def get_sales_order(api_key: str, order_id: str, company: str, fulfillment_center: str) -> Dict[str, Any]:
    try:
        headers = {
            "Content-Type": "application/json",
            "API-KEY-X": api_key,
        }

        params = {
            "salesOrderId": order_id,
            "company": company,
            "fulfillmentCenter": fulfillment_center
        }

        # logging.info(f"Request to Jasci API: GET https://uat-api.jasci.net/JasciRestApi/V2/salesOrder")
        # logging.info(f"Headers: {json.dumps(headers, indent=2)}")
        # logging.info(f"Params: {json.dumps(params, indent=2)}")

        response = requests.get("https://uat-api.jasci.net/JasciRestApi/V2/salesOrder", headers=headers, params=params)
        response.raise_for_status()

        data = response.json()

        product_values = [item["product"] for item in data["data"]["details"]]
        product_details = get_product_details(api_key, product_values)
        total_product_weight = sum(float(detail["productShippingWeight"]) for detail in product_details)
        logging.info(f"Total product weight: {total_product_weight}")

        required_details = {
            "salesOrderId": data["data"]["salesOrderId"],
            "fulfillmentCenterId": data["data"]["fulfillmentCenterId"],
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
            ],
            "totalProductWeight": total_product_weight
        }
        # logging.info(f"Successfully retrieved order details for order_id: {order_id}")
        return required_details
    except requests.exceptions.RequestException as e:
        error_message = f"Error retrieving order details for order_id {order_id}: {str(e)}"
        logging.error(error_message)
        
        error_details = []
        if "Address validation failed." in str(e):
            errors = str(e).split(';')
            for error in errors:
                if ':' in error:
                    code, description = error.strip().split(':', 1)
                    error_details.append({
                        "errorCode": code.strip(),
                        "errorDescription": description.strip()
                    })
        
        if not error_details:
            error_details.append({
                "errorCode": "REQUEST_EXCEPTION",
                "errorDescription": error_message
            })
        
        return {
            "error": True,
            "details": error_details
        }