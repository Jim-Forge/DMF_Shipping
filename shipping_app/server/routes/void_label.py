from flask import Flask, request, jsonify
import requests
import os

app = Flask(__name__)

SHIPIUM_API_KEY = os.getenv('SHIPIUM_API_KEY', 'your_default_api_key_here')

@app.route('/void_label', methods=['POST'])
def void_label():
    if request.json is None:
        return jsonify({"error": "Invalid JSON data"}), 400
    shipment_id = request.json.get('shipment_id')
    carrier_selection_id = request.json.get('carrier_selection_id')
    label_id = request.json.get('label_id')

    url = f"https://api.shipium.com/api/v1/deliveryexperience/shipment/{shipment_id}/carrierselection/{carrier_selection_id}/label/{label_id}/void"

    headers = {
        'accept': 'application/json',
        'content-type': 'application/json',
        'Authorization': f'Bearer {SHIPIUM_API_KEY}'
    }

    response = requests.post(url, headers=headers)

    if response.status_code == 200:
        return jsonify({"message": "Label voided successfully"}), 200
    else:
        return jsonify({"error": "Failed to void label", "details": response.text}), response.status_code

if __name__ == '__main__':
    app.run(debug=True)