import base64
import os
from PIL import Image
import logging
import requests
import io

label_image_popup = False

def render_label_image(base64_zpl, file_name="shipping_label.png", display_image=label_image_popup):
    try:
        logging.info("Starting to render label image")
        
        # Decode the base64 ZPL string
        zpl_data = base64.b64decode(base64_zpl).decode('utf-8')
        
        # Convert ZPL to image
        image = zpl_to_image(zpl_data)
        
        # Rotate the image 180 degrees
        image = image.rotate(180)
        
        logging.info("ZPL converted to image and rotated")
        
        image_path = os.path.abspath(file_name)
        logging.info(f"Attempting to save image to: {image_path}")
        image.save(image_path)
        logging.info(f"Label image saved to: {image_path}")
        
        if display_image:
            image.show()
        
        return image_path
    except Exception as e:
        logging.error(f"An error occurred while rendering the image: {e}")
        return None

def zpl_to_image(zpl_data):
    try:
        url = 'http://api.labelary.com/v1/printers/8dpmm/labels/4x6/0/'
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}
        response = requests.post(url, data=zpl_data, headers=headers)
        
        if response.status_code == 200:
            return Image.open(io.BytesIO(response.content))
        else:
            logging.error(f"Error from Labelary API: {response.status_code}, {response.text}")
            return Image.new('RGB', (400, 600), color='white')
    except Exception as e:
        logging.error(f"Error converting ZPL to image: {e}")
        return Image.new('RGB', (400, 600), color='white')