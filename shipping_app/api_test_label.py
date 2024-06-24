import requests
import base64
import json

API_KEY = '335b49e04a28f9d5d675e7c7d0e5d8907ca5d9c218506c1e04aa14be8a6799f2'  # Replace with your actual API key

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
    print(result)
except Exception as e:
    print(e)