const API_KEY = '335b49e04a28f9d5d675e7c7d0e5d8907ca5d9c218506c1e04aa14be8a6799f2'; // Replace with your actual API key

(async () => {
    try {
        const requestBody = {
            "currencyCode": "usd", //required
            "shipmentParameters": {
                "partnerShipmentId": null,
                "orderedDateTime": "2024-06-05T22:04:58.203Z",
                "shippedDateTime": "2024-06-05T22:04:58.203Z",
                "desiredDeliveryDate": null,
                "carrierName": null,
                "carrierTrackingId": null,
                "orderItemQuantities": [{
                    "productId": "554433",//required
                    "quantity": 2,//required
                    "productDetails": ["details"],//required
                    "shipiumOrderId": null,
                    "hazmat": false,
                    "hazmatInfo": {
                        "category": null,
                        "quantity": 0,
                        "quantityType": null,
                        "quantityUnits": null,
                        "containerType": null,
                        "hazmatId": null,
                        "properShippingName": null,
                        "packingGroup": null,
                        "transportMode": null,
                        "packingInstructionCode": null,
                        "hazardClass": null,
                        "subsidiaryClasses": null
                    }
                }],
                "shipFromAddress": { //required
                    "name": "20-NJ",
                    "phoneNumber": null,
                    "phoneNumberCountryCode": null,
                    "emailAddress": null,
                    "company": "N/A",
                    "street1": "14E Easy Street Bound Brook, NJ 08805",
                    "street2": null,
                    "city": "Bound Brook",
                    "state": "NJ",
                    "countryCode": "US",
                    "postalCode": "08805",
                    "addressType": "commercial"
                },
                "destinationAddress": { //required
                    "name": "Chelsea Jijawi",
                    "phoneNumber": "5555555555",
                    "phoneNumberCountryCode": null,
                    "emailAddress": null,
                    "company": "N/A",
                    "street1": "4207 N Elsinore Ave",
                    "street2": null,
                    "city": "Meridian",
                    "state": "ID",
                    "countryCode": "US",
                    "postalCode": "83646",
                    "addressType": "residential"
                },
                "shipOption": null,
                "packagingType": {
                    "packagingMaterial": "box",
                    "packagingSizeName": "test-package",
                    "packagingTypeId": null,
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
                "customsInfo": null,
                "saturdayDelivery": false,
                "fulfillmentContext": "test-tenant",
                "fulfillmentType": "customer",
                "tenantId": "test-tenant"
            },
            "generateLabel": true,
            "includeEvaluatedServiceMethodsInResponse": false,
            "labelParameters": {
                "currencyCode": "usd",
                "labelFormats": ["png", "zpl"],
                "includeLabelImagesInResponse": true,
                "customLabelEntries": {},
                "testMode": true,
                "contentDescription": "test-description",
            },
            "asOfDate": null,
            "carrierServiceMethodAllowList": []
        };

        console.log("Request Body:", JSON.stringify(requestBody, null, 2));

        const response = await fetch('https://api.shipium.com/api/v1/shipment/carrierselection/label', {
            method: 'POST',
            headers: {
                'Authorization': `Basic ${Buffer.from(API_KEY + ':').toString('base64')}`,
                'Content-Type': 'application/json',
                'accept': 'application/json',
            },
            body: JSON.stringify(requestBody)
        });

        if (!response.ok) {
            const errorDetails = await response.text();
            throw new Error(`Request failed with status code ${response.status}: ${errorDetails}`);
        }

        const result = await response.json();
        console.log(result);
    } catch (e) {
        console.error(e);
    }
})();