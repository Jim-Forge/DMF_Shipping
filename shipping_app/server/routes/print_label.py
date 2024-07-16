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

def print_shipping_label(base64_zpl, is_zpl, printer_name):
    try:
        if is_zpl:
            # Decode the base64 ZPL string
            zpl_data = base64.b64decode(base64_zpl).decode('utf-8')

            if platform.system() == "Windows":
                # Windows printing
                printer_name = win32print.GetDefaultPrinter()
                try:
                    hPrinter = win32print.OpenPrinter(printer_name)
                    try:
                        hJob = win32print.StartDocPrinter(hPrinter, 1, ("Shipping Label", "", "RAW"))
                        win32print.StartPagePrinter(hPrinter)
                        win32print.WritePrinter(hPrinter, zpl_data.encode('utf-8'))
                        win32print.EndPagePrinter(hPrinter)
                        win32print.EndDocPrinter(hPrinter)
                    finally:
                        win32print.ClosePrinter(hPrinter)
                except Exception as e:
                    logging.error(f"Error setting up Windows printer: {str(e)}")
                    return  # Exit the function if we can't set up the printer
            else:
                # Unix-like systems printing (Linux, macOS)
                try:
                    lpr = subprocess.Popen(["/usr/bin/lpr"], stdin=subprocess.PIPE)
                    if lpr.stdin is None:
                        raise ValueError("Failed to open stdin for lpr process")
                    lpr.stdin.write(zpl_data.encode('utf-8'))
                    lpr.stdin.close()
                    lpr.wait()  # Wait for the process to complete
                    if lpr.returncode != 0:
                        raise subprocess.CalledProcessError(lpr.returncode, "/usr/bin/lpr")
                except (subprocess.SubprocessError, ValueError) as e:
                    logging.error(f"Error printing on Unix-like system: {str(e)}")
                else:
                    logging.info("Shipping label printed successfully on Unix-like system")
        else:
            # Decode the base64 image
            image_data = base64.b64decode(base64_zpl)
            image = Image.open(io.BytesIO(image_data))

            if platform.system() == "Windows":
                # Windows printing
                printer_name = win32print.GetDefaultPrinter()
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
                    lpr = subprocess.Popen(["/usr/bin/lpr"], stdin=subprocess.PIPE)
                    if lpr.stdin is None:
                        raise ValueError("Failed to open stdin for lpr process")
                    lpr.stdin.write(image_data)
                    lpr.stdin.close()
                    lpr.wait()  # Wait for the process to complete
                    if lpr.returncode != 0:
                        raise subprocess.CalledProcessError(lpr.returncode, "/usr/bin/lpr")
                except (subprocess.SubprocessError, ValueError) as e:
                    logging.error(f"Error printing on Unix-like system: {str(e)}")
                else:
                    logging.info("Shipping label printed successfully on Unix-like system")
    except Exception as e:
        logging.error(f"Error printing shipping label: {str(e)}")