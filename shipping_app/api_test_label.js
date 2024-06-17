const axios = require('axios');
const assert = require('assert').strict;
const API_KEY = '335b49e04a28f9d5d675e7c7d0e5d8907ca5d9c218506c1e04aa14be8a6799f2'; // Replace with your actual API key

(async () => {
  try {
    const requestBody = {
      "currencyCode": "usd",
"shipmentParameters": {
"partnerShipmentId": null,
"orderedDateTime": "2022-12-14T00:00:00.000Z",
"shippedDateTime": "2022-12-14T00:00:00.000Z",
"desiredDeliveryDate": null,
"businessDaysOfTransit": null,
"ignoreUpgradeSpendLimits": false,
"deliveredDateTime": null,
"carrierName": null,
"carrierTrackingId": null,
"orderItemQuantities": [{
"productId": "123456",
"quantity": 1,
"productDetails": [],
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
"shipFromAddress": {
"name": "JGC NV FC",
"phoneNumber": "2065698244",
"phoneNumberCountryCode": null,
"emailAddress": null,
"company": "Just Great Cables",
"street1": "3200 USA Parkway",
"street2": null,
"city": "Sparks",
"state": "NV",
"countryCode": "US",
"postalCode": "89436",
"addressType": "commercial"
},
"destinationAddress": {
"name": "Joe Shipium",
"phoneNumber": "4445551212",
"phoneNumberCountryCode": null,
"emailAddress": null,
"company": "N/A",
"street1": "123 Shipium Dr",
"street2": null,
"city": "Seattle",
"state": "WA",
"countryCode": "US",
"postalCode": "98103",
"addressType": "residential"
},
"shipOption": "Standard",
"packagingType": {
"packagingMaterial": "box",
"packagingSizeName": "test-package",
"packagingTypeId": null,
"linearDimensions": {
"height": 10,
"length": 18,
"linearUnit": "in",
"width": 12
},
"packagingWeight": {
"weight": 25,
"weightUnit": "lb"
}
},
"totalWeight": {
"weight": 25,
"weightUnit": "lb"
},
"shipmentTags": ["test"],
"customsInfo": null,
"saturdayDelivery": false,
"deliverySignatureOption": "None",
"referenceIdentifier": "Example-Reference-ID",
"referenceIdentifier2": null,
"referenceIdentifier3": null,
"referenceIdentifier4": null,
"referenceIdentifier5": null,
"purchaseOrderIdentifier": null,
"fulfillmentContext": null,
"fulfillmentType": "customer",
"tenantId": null
},
"generateLabel": true,
"labelParameters": {
"currencyCode": "usd",
"labelFormats": ["zpl"],
"manifest": false,
"includeLabelImagesInResponse": true,
"customLabelEntries": {},
"testMode": true
},
"asOfDate": null,
"carrierServiceMethodAllowList": []
    };

    const result = await axios.post('https://api.shipium.com/api/v1/shipment/carrierselection/label', requestBody, {
      headers: {
        Authorization: `Basic ${Buffer.from(API_KEY + ':').toString('base64')}`,
        'Content-Type': 'application/json'
      }
    });
    console.log(result.data);
  } catch (e) {
    console.error(e);
  }
})();