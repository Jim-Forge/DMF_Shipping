from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Mock function to get order info
def get_order_info(order_id):
    # Replace with actual logic to fetch order info
    return {
        "order_id": order_id,
        "customer_name": "John Doe",
        "address": "123 Main St, Anytown, USA"
    }

# Mock function to generate shipping label
def generate_shipping_label(order_info):
    # Replace with actual logic to generate shipping label
    return {
        "label_url": "http://example.com/label.pdf"
    }

# Mock function to print the label
def print_label(label_url):
    # Replace with actual logic to print the label
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

if __name__ == '__main__':
    app.run(debug=True)