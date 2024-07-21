import base64
import platform
import io
import logging
from PIL import Image

if platform.system() == "Windows":
    import win32print
    import win32ui
    from PIL import ImageWin
else:
    import subprocess

def print_shipping_label(image_path, printer_name=None):
    try:
        image = Image.open(image_path)

        if platform.system() == "Windows":
            # Windows printing
            printer_name = printer_name or win32print.GetDefaultPrinter()
            try:
                hDC = win32ui.CreateDC()
                if hDC is None:
                    raise ValueError("Failed to create DC object")
        
                hDC.CreatePrinterDC(printer_name)
        
                hDC.StartDoc('Shipping Label')
                hDC.StartPage()

                page_width = hDC.GetDeviceCaps(110)  # PHYSICALWIDTH
                page_height = hDC.GetDeviceCaps(111)  # PHYSICALHEIGHT
                scale_width = page_width / image.width
                scale_height = page_height / image.height
                scale = min(scale_width, scale_height)

                x = (page_width - image.width * scale) / 2
                y = (page_height - image.height * scale) / 2

                dib = ImageWin.Dib(image)
                dib.draw(hDC.GetHandleOutput(), (int(x), int(y), int(x + image.width * scale), int(y + image.height * scale)))

                hDC.EndPage()
                hDC.EndDoc()
            except Exception as e:
                logging.error(f"Error setting up Windows printer: {str(e)}")
                return  # Exit the function if we can't set up the printer
            finally:
                if hDC:
                    hDC.DeleteDC()
        else:
            # Unix-like systems printing (Linux, macOS)
            try:
                subprocess.run(["lpr", image_path], check=True)
            except subprocess.CalledProcessError as e:
                logging.error(f"Error printing on Unix-like system: {str(e)}")
            else:
                logging.info("Shipping label printed successfully on Unix-like system")
    except Exception as e:
        logging.error(f"Error printing shipping label: {str(e)}")