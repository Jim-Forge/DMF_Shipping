import logging
import site
import os
from flask import Flask, request, jsonify
import base64
import sys

USER_ID_JASCI = "dmfintegrations@davincimfc.com"
PASSWORD_JASCI = "DavinC$2_2024"
SHIPIUM_API_KEY = os.getenv('SHIPIUM_API_KEY','65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c')

# Set up logging
# logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# Log Python path and current working directory
# logging.info(f"Python path: {sys.path}")
# logging.info(f"Current working directory: {os.getcwd()}")

# Log contents of the 'routes' directory
# routes_dir = os.path.join(os.getcwd(), 'routes')
# if os.path.exists(routes_dir):
#     logging.info(f"Contents of 'routes' directory: {os.listdir(routes_dir)}")
# else:
#     logging.error(f"'routes' directory not found at {routes_dir}")

sys.path.append(site.getusersitepackages())
from flask import Flask, request, jsonify
import base64

# Import routes and error handling
import_errors = []

try:
    from routes.address_validation import validate_address
    logging.debug("Successfully imported validate_address")
except ImportError as e:
    logging.error(f"Error importing validate_address: {str(e)}")
    import_errors.append(("validate_address", str(e)))

try:
    from routes.order_detail import get_sales_order
    logging.debug("Successfully imported get_sales_order")
except ImportError as e:
    logging.error(f"Error importing get_sales_order: {str(e)}")
    import_errors.append(("get_sales_order", str(e)))

try:
    from routes.carrier_label import create_shipment_label
    logging.debug("Successfully imported create_shipment_label")
except ImportError as e:
    logging.error(f"Error importing create_shipment_label: {str(e)}")
    import_errors.append(("create_shipment_label", str(e)))

try:
    from routes.render_label import render_label_image
    logging.debug("Successfully imported render_label_image")
except ImportError as e:
    logging.error(f"Error importing render_label_image: {str(e)}")
    import_errors.append(("render_label_image", str(e)))

try:
    from routes.print_label import print_shipping_label
    logging.debug("Successfully imported print_shipping_label")
except ImportError as e:
    logging.error(f"Error importing print_shipping_label: {str(e)}")
    import_errors.append(("print_shipping_label", str(e)))

try:
    from routes.error_alerting import handle_error, alert_on_error
    logging.debug("Successfully imported handle_error and alert_on_error")
except ImportError as e:
    logging.error(f"Error importing handle_error and alert_on_error: {str(e)}")
    import_errors.append(("error_alerting", str(e)))

try:
    from routes.api_key_jasci import get_api_key
    logging.debug("Successfully imported handle_error and alert_on_error")
except ImportError as e:
    logging.error(f"Error importing handle_error and alert_on_error: {str(e)}")
    import_errors.append(("error_alerting", str(e)))

if import_errors:
    logging.error(f"Failed to import the following modules: {', '.join([e[0] for e in import_errors])}")
    logging.error("Import errors details:")
    for module, error in import_errors:
        logging.error(f"  {module}: {error}")
    sys.exit(1)

# Log successful imports
# logging.info("All required modules imported successfully")

display_image_popup = True
auto_print_label = False

app = Flask(__name__)

# Retrieve the JASCI API key
# logging.info("Attempting to retrieve JASCI API key...")
JASCI_API_KEY = get_api_key(USER_ID_JASCI, PASSWORD_JASCI)
if not JASCI_API_KEY:
    logging.error("Failed to retrieve JASCI API key.")
    exit(1)
else:
    logging.info("Successfully retrieved JASCI API key.")
    # logging.debug(f"JASCI API key: {JASCI_API_KEY}")

@app.route('/health')
def health_check():
    return jsonify({"status": "ok"}), 200

@app.route('/process_order', methods=['POST'])
@alert_on_error
def process_order():
    # logging.info("Starting process_order")
    order_id = request.json.get('order_id') if request.json else None
    display_image = request.json.get('display_image', display_image_popup) if request.json else False
    print_label = request.json.get('print_label', auto_print_label) if request.json else False

    if not order_id:
        logging.warning("No order_id provided")
        return jsonify({"error": "order_id is required"}), 400
    
    # logging.info(f"Processing order: {order_id}")

    # Step 1: Get order details
    order_info = get_sales_order(str(JASCI_API_KEY), order_id, "Davinci Micro Fulfillment", "Bound Brook")
    # logging.debug(f"get_sales_order returned: {order_info}")
    if not order_info:
        error_info = handle_error("Failed to retrieve order information", "process_order", order_id, "Bound Brook")
        return jsonify({"error": error_info}), 400

    # Step 2: Validate address
    address_validation = validate_address(SHIPIUM_API_KEY, {
        'street1': order_info['addressLine1'],
        'city': order_info['city'],
        'state': order_info['stateCode'],
        'postalCode': order_info['zipCode'],
        'countryCode': 'US',
    }, order_info['fulfillmentCenterId'], order_info['salesOrderId'])
    # logging.debug(f"Address validation result: {address_validation}")

    if not address_validation.startswith("The address is valid"):
        error_info = handle_error(address_validation, "address_validation", order_id, order_info['fulfillmentCenterId'])
        return jsonify({"error": error_info}), 400

    # Step 3: Generate shipping label
    label_info = create_shipment_label(order_info)
    if not label_info:
        error_info = handle_error("Failed to generate shipping label", "create_shipment_label", order_id, order_info['fulfillmentCenterId'])
        return jsonify({"error": error_info}), 400
    
    # Step 4: Render and display label
    label_image_path = render_label_image(label_info['label_image'])
    if label_image_path:
        if print_label:
            print_shipping_label(label_image_path)
        
        encoded_image = None
        if display_image:
            with open(label_image_path, "rb") as image_file:
                encoded_image = base64.b64encode(image_file.read()).decode('utf-8')
        
        response_data = {
            "label_info": label_info,
            "label_image": encoded_image,
            "label_image_path": label_image_path
        }
        # logging.info(f"Successfully processed order: {order_id}")
        return jsonify(response_data)

    error_info = handle_error("Failed to render label image", "render_label_image", order_id, order_info['fulfillmentCenterId'])
    return jsonify({"error": error_info}), 500

@app.route('/print_label', methods=['POST'])
@alert_on_error
def print_label():
    # logging.info("Starting print_label")
    image_path = request.json.get('image_path') if request.json else None
    if not image_path:
        error_info = handle_error("No image path provided", "print_label")
        return jsonify({"error": error_info}), 400
    
    print_shipping_label(image_path)
    # logging.info(f"Successfully printed label: {image_path}")
    return jsonify({'message': 'Label printed successfully'}), 200

@app.errorhandler(Exception)
def handle_exception(e):
    # Pass the exception to the error handler
    error_info = handle_error(str(e), "server")
    return jsonify({"error": error_info}), 500

if __name__ == '__main__':
    logging.info("Starting Flask application")
    app.run(host='0.0.0.0', port=5001, debug=True)