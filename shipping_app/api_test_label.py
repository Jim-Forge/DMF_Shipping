import requests
import base64
import json

API_KEY = '65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c'  # Replace with your actual API key

try:
    request_body = {
        "currencyCode": "usd",
        "shipmentParameters": {
            "partnerShipmentId": None,
            "orderedDateTime": "2024-06-05T22:04:58.203Z",
            "shippedDateTime": "2024-06-05T22:04:58.203Z",
            "desiredDeliveryDate": None,
            "carrierName": None,
            "carrierTrackingId": None,
            "orderItemQuantities": [{
                "productId": "123456",
                "quantity": 1,
                "productDetails": [],
                "shipiumOrderId": None,
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
                "name": "Chelsea Jijawi",
                "phoneNumber": "5555555555",
                "phoneNumberCountryCode": None,
                "emailAddress": None,
                "company": "N/A",
                "street1": "4207 N Elsinore Ave",
                "street2": None,
                "city": "Meridian",
                "state": "ID",
                "countryCode": "US",
                "postalCode": "83646",
                "addressType": "residential"
            },
            "shipOption": None,
            "packagingType": {
                "packagingMaterial": "box",
                "packagingSizeName": "test-package",
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
            "customsInfo": None,
            "saturdayDelivery": False,
            "fulfillmentContext": "test-tenant",
            "fulfillmentType": "customer",
            "tenantId": "test-tenant"
        },
        "generateLabel": True,
        "includeEvaluatedServiceMethodsInResponse": False,
        "labelParameters": {
            "currencyCode": "usd",
            "labelFormats": ["png", "zpl"],
            "includeLabelImagesInResponse": False,
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
    ##print(result.carrierSelection)

    carrier_selection = result.get('carrierSelection')
    ##print(carrier_selection)

    # Example usage of get_nested_value
    carrier_name = get_nested_value(result, ['carrierSelection', 'carrierName'])
    print(f"Carrier Name: {carrier_name}")
except Exception as e:
    print(e)