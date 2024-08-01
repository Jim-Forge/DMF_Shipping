import requests
import sys
import json
import logging

# import_errors = []

# try:
#     from routes.error_alerting import handle_error
#     logging.debug("Successfully imported handle_error")
# except ImportError as e:
#     logging.error(f"Error importing handle_error: {str(e)}")
#     import_errors.append(("handle_error", str(e)))

# if import_errors:
#     logging.error(f"Failed to import the following modules: {', '.join([e[0] for e in import_errors])}")
#     logging.error("Import errors details:")
#     for module, error in import_errors:
#         logging.error(f"  {module}: {error}")
#     sys.exit(1)


def get_sales_order(api_key, order_id, company, fulfillment_center):
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

        # Log the full request body
        logging.info(f"Request to Jasci API: GET https://uat-api.jasci.net/JasciRestApi/V2/salesOrder")
        logging.info(f"Headers: {json.dumps(headers, indent=2)}")
        logging.info(f"Params: {json.dumps(params, indent=2)}")

        response = requests.get("https://uat-api.jasci.net/JasciRestApi/V2/salesOrder", headers=headers, params=params)
        response.raise_for_status()

        data = response.json()

        # Extract required details
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
            ]
        }
        logging.info(f"Successfully retrieved order details for order_id: {order_id}")
        return required_details
    except requests.exceptions.RequestException as e:
        error_message = f"Error retrieving order details for order_id {order_id}: {str(e)}"
        logging.error(error_message)
        
        # Parse the error message
        error_details = []
        if "Address validation failed." in error_message:
            # Split the error message by semicolons
            errors = error_message.split(';')
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