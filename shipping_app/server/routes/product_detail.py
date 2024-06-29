import requests
import json

def get_product_details(api_key, product_values):
    headers = {
        "API-KEY-X": api_key,
        "Content-Type": "application/json"
    }

    product_details = []

    for product_value in product_values:
        params = {
            "product": product_value
        }

        response = requests.get("https://uat-api.jasci.net/JasciRestApi/V2/productDetail", headers=headers, params=params)
        
        # Print the raw API response
        print(f"Raw API response for product {product_value}:")
        print(json.dumps(response.json(), indent=2))
        print("\n")  # Add a newline for better readability

        response.raise_for_status()

        data = response.json()

        product_detail = {
            "product": data["data"][0]["product"],
            "productShippingHeight": data["data"][0]["productShippingHeight"],
            "productShippingLength": data["data"][0]["productShippingLength"],
            "productShippingWidth": data["data"][0]["productShippingWidth"],
            "productShippingWeight": data["data"][0]["productShippingWeight"]
        }

        product_details.append(product_detail)

    return product_details

# Example usage
api_key = "ZG1maW50ZWdyYXRpb25zQGRhdmluY2ltZmMuY29tfERhdmluQyQxXzIwMjQ="
product_values = ["101036", "212527", "213290"]
# product_values = ["101036"]

product_details = get_product_details(api_key, product_values)
print("Final processed product details:")
print(json.dumps(product_details, indent=2))