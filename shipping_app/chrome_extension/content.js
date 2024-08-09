document.addEventListener('click', function(e) {
    if (e.target && e.target.id === 'shippingAppButton') {
        const orderId = document.getElementById('orderIdInput').value;
        if (orderId) {
            // Send a message to the background script with the order ID
            chrome.runtime.sendMessage({type: "ORDER_ID", orderId: orderId});
        } else {
            console.log('Please enter an Order ID');
        }
    }
});