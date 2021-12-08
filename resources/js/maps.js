function leafletMaps(json) {
    var terrain = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
        attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
    });
    
    /* Not added by default, only through user control action */
    var streets = L.tileLayer('http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', {
        attribution: "ISAW, 2012"
    });
    
    var imperium = L.tileLayer('http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {
        attribution: 'Tiles: &lt;a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html"&gt;Pelagios&lt;/a&gt;, 2012; Data: NASA, OSM, Pleiades, DARMC', maxZoom: 11
    });
    
    var placesgeo = json
    
    var geojson = L.geoJson(placesgeo, { onEachFeature: function (feature, layer) {
            var typeText = feature.properties.type
            var popupContent =
            "<a href='" + feature.properties.uri + "' class='map-pop-title'>" +
            feature.properties.name + "</a>" + (feature.properties.type ? "Type: " + typeText: "") +
            (feature.properties.desc ? "<span class='map-pop-desc'>" + feature.properties.desc + "</span>": "");
            layer.bindPopup(popupContent);
        }
    })
    
    var map = L.map('map', {
        scrollWheelZoom: false
    }).fitBounds(geojson.getBounds(), {
        maxZoom: 5
    }).setZoom(5);
    
    terrain.addTo(map);
    
    L.control.layers({
        "Terrain (default)": terrain,
        "Streets": streets,
        "Imperium": imperium
    }).addTo(map);
    
    geojson.addTo(map);
}