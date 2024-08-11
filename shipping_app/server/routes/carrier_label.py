import requests
import base64
import json
import os
import logging
import functools
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load API key from environment variable
API_KEY = os.getenv('SHIPIUM_API_KEY', '65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c')  # Replace with your actual API key or set it in the environment



def alert_on_error(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            logging.error(f"Error in {func.__name__}: {str(e)}")
            # Here you could add additional alerting logic, such as sending an email or a notification
            raise  # Re-raise the exception after logging
    return wrapper

def get_nested_value(dictionary, keys):
    if not keys:
        return dictionary
    if isinstance(dictionary, dict):
        return get_nested_value(dictionary.get(keys[0]), keys[1:])
    return None
@alert_on_error
def create_shipment_label(order_info):
    try:
        request_body = {
            "currencyCode": "usd",
            "shipmentParameters": {
                "orderedDateTime": "2024-07-15T17:00:00.0Z",
                "shippedDateTime": "2024-07-15T17:00:00.0Z",
                "desiredDeliveryDate": "2024-10-15T17:00:00.0Z",
                "preferredCarrierDeliveryDateTime": "2024-10-15T17:00:00.0Z",
                "includePackagesArray": True,
                "ignoreUpgradeSpendLimits": False,
                "orderItemQuantities": [{
                    "productId": "123456",
                    "quantity": 1,
                    "hazmat": False,
                    "hazmatInfo": {
                        "category": None,
                        "quantity": 0,
                        "quantityType": None,
                        "quantityUnits": None,
                        "containerType": None,
                        "hazmatId": None,
                        "properShippingName": None,
                        "packingGroup": None,
                        "transportMode": None,
                        "packingInstructionCode": None,
                        "hazardClass": None,
                        "subsidiaryClasses": None
                    }
                }],
                "shipFromAddress": {
                    "name": "20-NJ",
                    "phoneNumber": None,
                    "phoneNumberCountryCode": None,
                    "emailAddress": None,
                    "company": "N/A",
                    "street1": "14E Easy Street Bound Brook, NJ 08805",
                    "street2": None,
                    "city": "Bound Brook",
                    "state": "NJ",
                    "countryCode": "US",
                    "postalCode": "08805",
                    "addressType": "commercial"
                },
                "destinationAddress": {
                    "name": order_info['firstName']+" "+order_info['lastName'],
                    "phoneNumber": "5555555",
                    "phoneNumberCountryCode": None,
                    "emailAddress": None,
                    "company": None,
                    "street1": order_info['addressLine1'],
                    "street2": order_info.get('addressLine2', None),
                    "city": order_info['city'],
                    "state": order_info['stateCode'],
                    "countryCode": "US",
                    "postalCode": order_info['zipCode'],
                    "addressType": "residential"
                },
                "packagingType": {
                    "packagingMaterial": "box", #required
                    "packagingSizeName": None,
                    "packagingTypeId": None,
                    "linearDimensions": {
                        "linearUnit": "in",
                        "length": 9,
                        "width": 7,
                        "height": 3
                    },
                    "packagingWeight": {
                        "weightUnit": "lb",
                        "weight": 3
                    }
                },
                "totalWeight": {
                    "weightUnit": "lb",
                    "weight": 3
                },
                "shipmentTags": [],
                "saturdayDelivery": False,
                "fulfillmentContext": "test-tenant",
                "fulfillmentType": "customer",
                "tenantId": "test-tenant"
            },
            "generateLabel": True,
            "includeEvaluatedServiceMethodsInResponse": False,
            "labelParameters": {
                "currencyCode": "usd",
                "labelFormats": ["zpl"],
                "includeLabelImagesInResponse": True,
                "customLabelEntries": {},
                "testMode": True
            },
            "asOfDate": None,
            "carrierServiceMethodAllowList": []
        }
    
        headers = {
            'Authorization': f'Basic {base64.b64encode((API_KEY + ":").encode()).decode()}',
            'Content-Type': 'application/json'
        }

        response = requests.post('https://api.shipium.com/api/v1/shipment/carrierselection/label', headers=headers, data=json.dumps(request_body))

        if response.status_code != 200:
            raise Exception(f"Request failed with status code {response.status_code}: {response.text}")

        result = response.json()

        label_info = {}
        label_info['carrier'] = get_nested_value(result, ['carrierSelection', 'carrier'])
        label_info['tracking_number'] = get_nested_value(result, ['carrierLabel', 'packageScannableId'])
        label_info['service_method'] = get_nested_value(result, ['carrierSelection', 'serviceMethodName'])

        # logging.info(f"Carrier: {label_info['carrier']}")
        # logging.info(f"Tracking Number: {label_info['tracking_number']}")
        # logging.info(f"Service Method: {label_info['service_method']}")

        documents = get_nested_value(result, ['carrierLabel', 'documents'])

        if documents and isinstance(documents, list) and len(documents) > 0:
            label_info['label_image'] = documents[0].get('labelImage', {}).get('imageContents')
            # logging.info(f"Label Image: {label_info['label_image']}")
        else:
            logging.error("Documents array is empty or not in the expected format")
            label_info['label_image'] = None

        return label_info

    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return None
    
# if __name__ == "__main__":
#     # Create a sample order_info dictionary
#     order_info = {
#         'orderId': '7',  # Add this line
#         'firstName': 'John',
#         'lastName': 'Doe',
#         'addressLine1': '123 Main St',
#         'city': 'Anytown',
#         'stateCode': 'NY',
#         'zipCode': '12345'
#     }

#     try:
#         result = create_shipment_label(order_info)
        
#         if result:
#             print("Shipment label created successfully.")
#             print(f"Carrier: {result['carrier']}")
#             print(f"Tracking Number: {result['tracking_number']}")
#             print(f"Service Method: {result['service_method']}")
#         else:
#             print("Failed to create shipment label.")
#     except Exception as e:
#         print(f"An error occurred: {str(e)}")