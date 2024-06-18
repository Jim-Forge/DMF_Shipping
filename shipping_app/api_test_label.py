from flask import Flask, request, jsonify
import requests
import base64
import json

app = Flask(__name__)

API_KEY = '335b49e04a28f9d5d675e7c7d0e5d8907ca5d9c218506c1e04aa14be8a6799f2'  # Replace with your actual API key

# Mock function to validate address
def validate_address(address):
    if address["countryCode"] == "US" and address["postalCode"].isdigit():
        return {"valid": True}
    else:
        return {"valid": False}

@app.route('/validate_address', methods=['POST'])
def validate_address_endpoint():
    address = request.json.get('address')
    if not address:
        return jsonify({"error": "address is required"}), 400
    
    validation_result = validate_address(address)
    return jsonify(validation_result)

# Mock function to get order info
def get_order_info(order_id):
    return {
        "order_id": order_id,
        "customer_name": "John Doe",
        "address": "123 Main St, Anytown, USA"
    }

# Mock function to generate shipping label
def generate_shipping_label(order_info):
    return {
        "label_url": "http://example.com/label.pdf"
    }

# Mock function to print the label
def print_label(label_url):
    print(f"Printing label from {label_url}")

@app.route('/get_order_info', methods=['GET'])
def order_info():
    order_id = request.args.get('order_id')
    if not order_id:
        return jsonify({"error": "order_id is required"}), 400
    
    order_info = get_order_info(order_id)
    return jsonify(order_info)

@app.route('/generate_label', methods=['POST'])
def generate_label():
    order_info = request.json
    if not order_info:
        return jsonify({"error": "order_info is required"}), 400
    
    label_info = generate_shipping_label(order_info)
    return jsonify(label_info)

@app.route('/print_label', methods=['POST'])
def print_label_endpoint():
    label_url = request.json.get('label_url')
    if not label_url:
        return jsonify({"error": "label_url is required"}), 400
    
    print_label(label_url)
    return jsonify({"status": "Label printed successfully"})

@app.route('/create_shipment', methods=['POST'])
def create_shipment():
    try:
        request_body = request.json
        headers = {
            'Authorization': f'Basic {base64.b64encode((API_KEY + ":").encode()).decode()}',
            'Content-Type': 'application/json'
        }

        response = requests.post('https://api.shipium.com/api/v1/shipment/carrierselection/label', headers=headers, data=json.dumps(request_body))

        if response.status_code != 200:
            return jsonify({"error": f"Request failed with status code {response.status_code}: {response.text}"}), response.status_code

        result = response.json()
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)