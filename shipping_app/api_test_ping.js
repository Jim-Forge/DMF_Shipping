const API_KEY = '65cfb6fee3b3d46497e66d4323df96565ca8da6cc5f83b83008ffb79e276c70c'; // Replace with your actual API key

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