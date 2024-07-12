import requests
import base64
import json
import os
import logging
from PIL import Image
import io

result = 'XlhBXkNGLDAsMCwwXlBSMTJeTUQzMF5QT0leQ0kxM15MSDAsMjAKXkZPMTIsMTI0XkdCNzU1LDIsMl5GUwpeRk8xMiwzOTBeR0I3NzcsMiwyXkZTCl5GTzMyLDNeQWROLDAsMF5GV05eRkheRkRGUk9NOl5GUwpeRk8zMiwxOV5BZE4sMCwwXkZXTl5GSF5GRERhbmllbCBXb29kbWFuXkZTCl5GTzMyLDM3XkFkTiwwLDBeRldOXkZIXkZERGF2aW5jaV5GUwpeRk8zMiw1NV5BZE4sMCwwXkZXTl5GSF5GRDE0RSBFYXN5IFN0cmVldCBCb3VuZCBCcm9vaywgTkpeRlMKXkZPMzIsNzNeQWROLDAsMF5GV05eRkheRkQwODgwNV5GUwpeRk8zMiwxMDleQWROLDAsMF5GV05eRkheRkRVUyBeRlMKXkZPMjI0LDNeQWROLDAsMF5GV05eRkheRkQxNzMyODAzMzczM15GUwpeRk8yOCw3NDJeQTBOLDI0LDI0XkZXTl5GSF5GRFRSSyNeRlMKXkZPMjgsODAwXkEwTiwyNywzMl5GV05eRkheRkReRlMKXkZPMTM2LDcxMl5BME4sMjcsMzZeRldOXkZIXkZEXkZTCl5GTzMyLDkxXkFkTiwwLDBeRldOXkZIXkZEQm91bmQgQnJvb2sgTkogMDg4MDVeRlMKXkZPNDc4LDNeQWROLDAsMF5GV05eRkheRkRTSElQIERBVEU6IDEySlVMMjReRlMKXkZPNDc4LDE5XkFkTiwwLDBeRldOXkZIXkZEQUNUV0dUOiAzLjAwIExCXkZTCl5GTzQ3OCwzN15BZE4sMCwwXkZXTl5GSF5GRENBRDogMDAwMDAwMC9XU1hJMzYwMF5GUwpeRk80NzgsOTFeQWROLDAsMF5GV05eRkheRkRCSUxMIFNFTkRFUl5GUwpeRk8zOSwxMzZeQTBOLDM5LDM5XkZXTl5GSF5GRENoZWxzZWEgSmlqYXdpXkZTCl5GTzM5LDE3OF5BME4sMzksMzleRldOXkZIXkZETi9BXkZTCl5GTzM5LDIyMF5BME4sMzksMzleRldOXkZIXkZENDIwNyBOIEVsc2lub3JlIEF2ZV5GUwpeRk8zOSwyNjJeQTBOLDM5LDM5XkZXTl5GSF5GRCoqVEVTVCBMQUJFTCAtIERPIE5PVCBTSElQKipeRlMKXkZPMzksMzQ3XkFkTiwwLDBeRldOXkZIXkZEKDU1NSkgNTU1LTU1NTVeRlMKXkZPMzksMzA0XkEwTiw0Myw0MF5GV05eRkheRkRNZXJpZGlhbiBJRCA4MzY0Nl5GUwpeRk83MTksMzA0XkEwTiw0Myw0MF5GV05eRkheRkQoVVMpXkZTCl5GTzY3Nyw0NjJeR0IxMDQsMTAsMTBeRlMKXkZPNjc3LDQ3Ml5HQjEwLDExMiwxMF5GUwpeRk83NzEsNDcyXkdCMTAsMTEyLDEwXkZTCl5GTzY3Nyw1ODReR0IxMDQsMTAsMTBeRlMKXkZPNDY0LC0tXkdCMiwxMjYsMl5GUwpeRk82ODcsNDgwXkEwTiwxMjgsMTM3XkZXTl5GSF5GREheRlMKXkZPNjU0LDQwMl5BME4sNDMsNTheRldOXkZIXkZERmVkRXheRlMKXkZPNjYzLDQ0OF5BYk4sMTEsN15GV05eRkheRkRIb21lIERlbGl2ZXJ5XkZTCl5GTzc5MSw0OTNeQTBOLDEzLDE4XkZXQl5GSF5GREoyNDMwMjQwNzA5MDF1dl5GUwpeRk85LDEzNl5BME4sMjEsMjFeRldOXkZIXkZEVE9eRlMKXkZPMjEsNDEyXkJZMiwyXkI3TiwxMCw1LDE0XkZIXkZXTl5GSF5GRFspPl8xRTAxXzFEMDI4MzY0Nl8xRDg0MF8xRDgwNF8xRDc5NDY0NzcxNjk4OF8xREZERUdfMUQ4MDAwMzAyXzFEMTk0XzFEXzFEMS8xXzFEMy4wMExCXzFETl8xRDQyMDcgTiBFbHNpbm9yZSBBdmVfMURNZXJpZGlhbl8xRElEXzFEQ2hlbHNlYSBKaWphd2lfMUUwNl8xRDEwWkdIMDA3XzFEMTFaTi9BXzFEMTJaNTU1NTU1NTU1NV8xRDIwWl8xQ18xRDMxWjk2MjIwODA0MzAwMDgwMDAzMDI5MDA3OTQ2NDc3MTY5ODhfMURfMUVfMDReRlMKXkZPMjgsODM3XkEwTiwxMDcsOTZeRldOXkZIXkZEXkZTCl5GTzEyLDY4MV5HQjc3NywyLDJeRlMKXkZPNDk0LDg4NV5BME4sNDMsNDNeRldOXkZIXkZEXkZTCl5GTzc4OCwyOF5BYk4sMTEsN15GV0JeRkheRkQ1ODNKOS9FMEU0LzlBRTNeRlMKXkZPOTUsNzQ2XkEwTiw1Myw0MF5GV05eRkheRkQwMDAwIDAwMDAgMDAwMF5GUwpeRk80MDksNjk1XkEwTiw1MSwzOF5GV05eRkheRkIzOTAsLCxSLF5GRCAgICAgICAgICAgICAgICAgICBeRlMKXkZPNDA0LDc0N15BME4sNTEsMzheRldOXkZIXkZCNDAwLCwsUixeRkQgICAgICAgICAgICAgICAgICAgXkZTCl5GTzQxMyw3OTleQTBOLDQwLDQwXkZXTl5GSF5GQjM4NiwsLFIsXkZEICAgICAgICAgICAgICAgIF5GUwpeRk80OTUsODQxXkEwTiw0NCw0NF5GV05eRkheRkIyOTgsLCxSLF5GRCAgICAgODM2NDZeRlMKXkZPNTc0LDkwMV5BME4sMjQsMjReRldOXkZIXkZCMTIwLCwsUixeRkQgICAgICBeRlMKXkZPNjk1LDg4NV5BME4sNDMsNDNeRldOXkZIXkZCMTAwLCwsUixeRkQgICBeRlMKXkZPMzksOTI3XkEwTiwyNywzNl5GV05eRkheRkQwMDAwIDAwMDAgMCAoMDAwIDAwMCAwMDAwKSAwIDAwIDAwMDAgMDAwMCAwMDAwXkZTCl5GTzc1LDk2OF5CWTMsMl5CQ04sMjAwLE4sTixOLE5eRldOXkZEPjs5NjIyMDgwNDMwMDA4MDAwMzAyOTAwMDAwMDAwMDAwMDAwXkZTCl5GTzEzNSwxMDI4XkEwTiwxMjgsMTM3XkZXTl5GSF5GRFNBTVBMRV5GUwpeRk80NzgsNTVeQWROLDAsMF5GV05eRkheRkRESU1NRUQ6IDkgWCA3IFggMyBJTl5GUwpeRk8zMjksMzQ5XkFiTiwxMSw3XkZXTl5GSF5GRFJFRjogXkZTCl5GTzM5LDM2M15BYk4sMTEsN15GV05eRkheRkRJTlY6IF5GUwpeRk8zOSwzNzdeQWJOLDExLDdeRldOXkZIXkZEUE86IF5GUwpeRk80MjksMzc3XkFiTiwxMSw3XkZXTl5GSF5GRERFUFQ6IF5GUwpeUFExCl5YWgo='

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

API_KEY = os.getenv('SHIPIUM_API_KEY', '65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c')

def render_label_image(base64_image, file_name="shipping_label.png"):
    try:
        logging.info("Starting to render label image")
        image_data = base64.b64decode(base64_image)
        logging.info("Base64 data decoded")
        image = Image.open(io.BytesIO(image_data))
        logging.info("Image opened")
        image_path = os.path.abspath(file_name)
        logging.info(f"Attempting to save image to: {image_path}")
        image.save(image_path)
        logging.info(f"Label image saved to: {image_path}")
        image.show()
        return image_path
    except Exception as e:
        logging.error(f"An error occurred while rendering the image: {e}")
        return None

def get_nested_value(data, keys):
    for key in keys:
        if isinstance(data, dict) and key in data:
            data = data[key]
        else:
            return None
    return data

def create_shipment_label():
    try:
        # Since result is already a string, we can use it directly
        label_image = result
        if label_image:
            logging.info(f"Label Image (first 50 characters): {label_image[:50]}...")
            return render_label_image(label_image)
        else:
            logging.warning("Label image not found in the response.")
        return None
    except Exception as e:
        logging.error(f"An error occurred while creating the shipment label: {e}")
        return None