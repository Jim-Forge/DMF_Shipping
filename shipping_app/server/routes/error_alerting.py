import requests
import logging
import functools
import json
import os

# from routes.error_alerting import handle_error, alert_on_error

# Load the Teams webhook URL from an environment variable
TEAMS_WEBHOOK_URL = os.environ.get('TEAMS_WEBHOOK_URL','https://davincisupplychaincom.webhook.office.com/webhookb2/66691c8a-21ea-4667-ab90-7209ffd6ded5@96e92e73-d63a-4510-b8f1-c0aa117069c4/IncomingWebhook/f35e4fd5e3074ea886fb0c77eb7bf634/8c412233-387d-441d-9931-2d51ebaa8758')

def handle_error(error, context="", order_id=None, warehouse=None):
    error_message = {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "content": {
                    "type": "AdaptiveCard",
                    "body": [
                        {
                            "type": "TextBlock",
                            "size": "Medium",
                            "weight": "Bolder",
                            "text": f"Error in {context}"
                        },
                        {
                            "type": "FactSet",
                            "facts": [
                                {"title": "Order ID", "value": order_id or "N/A"},
                                {"title": "Warehouse", "value": warehouse or "N/A"}
                            ]
                        },
                        {
                            "type": "TextBlock",
                            "text": str(error),
                            "wrap": True
                        }
                    ],
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "version": "1.2"
                }
            }
        ]
    }
    
    logging.error(json.dumps(error_message, indent=2))
    
    try:
        if TEAMS_WEBHOOK_URL:
            response = requests.post(TEAMS_WEBHOOK_URL, json=error_message)
            if response.status_code != 200:
                logging.error(f"Failed to send Teams alert: {response.text}")
            else:
                logging.info("Teams alert sent successfully")
        else:
            logging.warning("TEAMS_WEBHOOK_URL is not set. Teams alert not sent.")
    except Exception as e:
        logging.error(f"Error sending Teams alert: {str(e)}")

    # Return structured error message for UI display
    return {
        "context": context,
        "order_id": order_id or "N/A",
        "warehouse": warehouse or "N/A",
        "error_details": str(error)
    }

def alert_on_error(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            # Extract order_id and warehouse from kwargs if they exist
            order_id = kwargs.get('order_id')
            warehouse = kwargs.get('warehouse')
            
            # If not in kwargs, try to find them in args
            if order_id is None and len(args) > 0 and isinstance(args[0], dict):
                order_id = args[0].get('salesOrderId')
            if warehouse is None and len(args) > 0 and isinstance(args[0], dict):
                warehouse = args[0].get('fulfillmentCenterId')
            
            error_info = handle_error(e, func.__name__, order_id=order_id, warehouse=warehouse)
            raise Exception(json.dumps(error_info))  # Raise a new exception with the structured error info
    return wrapper

logging.basicConfig(level=logging.INFO)