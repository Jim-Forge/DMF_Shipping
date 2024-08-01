
import requests
import base64
import json
import logging
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
import_errors = []

try:
    from routes.error_alerting import handle_error
    logging.debug("Successfully imported handle_error")
except ImportError as e:
    logging.error(f"Error importing handle_error: {str(e)}")
    import_errors.append(("handle_error", str(e)))

# try:
#     from routes.error_alerting import alert_on_error
#     logging.debug("Successfully imported alert_on_error")
# except ImportError as e:
#     logging.error(f"Error importing alert_on_error: {str(e)}")
#     import_errors.append(("alert_on_error", str(e)))

# @alert_on_error
def validate_address(shipium_api_key, address, warehouse, order_id):
    url = "https://api.shipium.com/api/v1/address/validate"

    headers = {
        "Authorization": f'Basic {base64.b64encode((shipium_api_key + ":").encode()).decode()}',
        "Content-Type": "application/json",
    }

    payload = {
        "address": address,
        "ignoreSecondaryAddressMismatch": "false",
        "includeCandidate": "true",
    }

    try:
        response = requests.post(url, headers=headers, data=json.dumps(payload))
        response.raise_for_status()
        result = response.json()

        if not result.get("valid"):
            error_details = result.get("details", [])
            error_message = "Address validation failed."
            for detail in error_details:
                error_message += f"\n{detail['errorCode']}: {detail['errorDescription']}"
            handle_error(ValueError(error_message), "validate_address", order_id=order_id, warehouse=warehouse)
            return error_message

        # Process valid address response
        message = "The address is valid."
        details = result.get("details", [])
        if details:
            message += "\nDetails:"
            for detail in details:
                message += f"\n{detail['errorCode']}: {detail['errorDescription']}"

        candidate = result.get("candidate")
        if candidate:
            message += f"\nCandidate: {json.dumps(candidate, indent=2)}"

        return message

    except requests.exceptions.RequestException as e:
        error_message = f"A network error occurred during address validation:\n{str(e)}"
        handle_error(e, "validate_address", order_id=order_id, warehouse=warehouse)
        return error_message

    # TEST ////////////////////////////// TEST ////////////////////////////


def test_address_validation(shipium_api_key):
    # Valid address
    # valid_address = {
    #     "street1": "1600 Amphitheatre Parkway",
    #     "city": "Mountain View",
    #     "state": "CA",
    #     "postalCode": "94043",
    #     "countryCode": "US",
    # }

    # Invalid address
    invalid_address = {
        "street1": "123 Nonexistent Street",
        "city": "Faketown",
        "state": "ZZ",
        "postalCode": "00000",
        "countryCode": "US",
    }

    # print("Testing valid address:")
    # print(validate_address(shipium_api_key, valid_address))
    # print("\nTesting invalid address:")
    # print(validate_address(shipium_api_key, invalid_address))


if __name__ == "__main__":
    # Replace with your actual Shipium API key
    shipium_api_key = "65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c"
    test_address_validation(shipium_api_key)
