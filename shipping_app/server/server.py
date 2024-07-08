from flask import Flask, request, jsonify
import requests
from routes.address_validation import validate_address
from routes.order_detail import get_sales_order
from routes.carrier_label import create_shipment_label
import os
# from routes.api_key import API_KEY
API_KEY = os.getenv('SHIPIUM_API_KEY', '65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c')

app = Flask(__name__)

@app.route('/process_order', methods=['POST'])
def process_order():
    order_id = request.json.get('order_id') if request.json else None
    if not order_id:
        return jsonify({"error": "order_id is required"}), 400
    
    try:
        # Step 1: Get order details
        order_info = get_sales_order(API_KEY, order_id, "Davinci Micro Fulfillment", "Bound Brook")
        if not order_info:
            return jsonify({"error": "Failed to retrieve order information"}), 400

        # Step 2: Validate address
        address_validation = validate_address(order_info['addressLine1'], order_info['city'], order_info['stateCode'], order_info['zipCode'], order_info['countryCode'])
        if not address_validation.get('valid'):
            return jsonify({"error": "Invalid address"}), 400

        # Step 3: Generate shipping label
        label_info = create_shipment_label(order_info)
        if not label_info:
            return jsonify({"error": "Failed to generate shipping label"}), 400

        return jsonify(label_info)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
    app.run(host='0.0.0.0', port=5000)