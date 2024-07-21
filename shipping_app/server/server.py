#!/usr/bin/env python3
import site
import sys
sys.path.append(site.getusersitepackages())
from flask import Flask, request, jsonify
import requests
from routes.address_validation import validate_address
from routes.order_detail import get_sales_order
from routes.carrier_label import create_shipment_label
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# API key setup
SHIPIUM_API_KEY = os.getenv('SHIPIUM_API_KEY', '65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c')
JASCI_API_KEY = os.getenv('JASCI_API_KEY', 'ZG1maW50ZWdyYXRpb25zQGRhdmluY2ltZmMuY29tfERhdmluQyQxXzIwMjQ=')

@app.route('/process_order', methods=['POST'])
def process_order():
    order_id = request.json.get('order_id') if request.json else None
    if not order_id:
        return jsonify({"error": "order_id is required"}), 400
    
    try:
        # Step 1: Get order details
        order_info = get_sales_order(JASCI_API_KEY, order_id, "Davinci Micro Fulfillment", "Bound Brook")
        print(f"Debug: get_sales_order returned: {order_info}")  # Add this line for debugging
        if not order_info:
            return jsonify({"error": "Failed to retrieve order information", "order_id": order_id}), 400
        # return jsonify({"success": True, "message": "Order information retrieved successfully", "order_info": order_info})


        # Step 2: Validate address
        # Modify this line in the process_order function
        address_validation = validate_address(SHIPIUM_API_KEY, {
            'street1': order_info['addressLine1'],
            'city': order_info['city'],
            'state': order_info['stateCode'],
            'postalCode': order_info['zipCode'],
            'countryCode': 'US',
            # 'addressType': 'commercial'
        })

        if not address_validation.startswith("The address is valid"):
            return jsonify({"error": "Invalid address", "details": address_validation}), 400

        # Step 3: Generate shipping label
        label_info = create_shipment_label(order_info, SHIPIUM_API_KEY)
        if not label_info:
            return jsonify({"error": "Failed to generate shipping label"}), 400

        return jsonify(label_info)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)