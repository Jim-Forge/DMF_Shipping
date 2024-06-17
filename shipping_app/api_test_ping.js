const API_KEY = '335b49e04a28f9d5d675e7c7d0e5d8907ca5d9c218506c1e04aa14be8a6799f2'; // Replace with your actual API key

const myHeaders = new Headers();
myHeaders.append("Authorization", `Basic ${Buffer.from(API_KEY + ':').toString('base64')}`);

const requestOptions = {
  method: "GET",
  headers: myHeaders,
  redirect: "follow"
};

fetch("https://api.shipium.com/api/v1/deliveryexperience/ping", requestOptions)
  .then((response) => response.text())
  .then((result) => console.log(result))
  .catch((error) => console.error(error));