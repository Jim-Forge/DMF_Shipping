chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.type === "ORDER_ID") {
        console.log("Order ID received:", message.orderId);
        // Send the message to the shipping app
        chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
            if (tabs.length > 0) {
                chrome.tabs.sendMessage(tabs[0].id, {type: "UPDATE_ORDER_ID", orderId: message.orderId});
            }
        });
    }
});