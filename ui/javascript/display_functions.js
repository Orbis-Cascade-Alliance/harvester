$(document).ready(function () {
    var lat = $('#lat').text();
    var lon = $('#long').text();
    var map = L.map('map').setView([lat, lon], 13);
    
    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);
    L.marker([lat, lon]).addTo(map).bindPopup('A pretty CSS3 popup.<br> Easily customizable.');
});
