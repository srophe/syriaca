xquery version "3.0";

module namespace maps = "http://srophe.org/srophe/maps";

(:~
 : Module builds leafletjs maps and/or Google maps
 : Pulls geoJSON from http://syriaca.org/geojson module. 
 : 
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)
import module namespace geojson = "http://srophe.org/srophe/geojson" at "../content-negotiation/geojson.xqm";
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : Selects map rendering based on config.xml entry
:)
declare function maps:build-map($nodes as node()*, $total-count as xs:integer?){
if($config:app-map-option = 'google') then maps:build-google-map($nodes)
else maps:build-leaflet-map($nodes,$total-count)
};

declare function maps:build-dynamic-map($nodes as node()*, $total-count as xs:integer?, $currentID as xs:string?){
    maps:dynamic-leaflet-map($nodes,$total-count)
};

(:~
 : Build leafletJS map
:)
declare function maps:dynamic-leaflet-map($nodes as node()*, $total-count as xs:integer?){
    <div id="map-data" style="margin-bottom:3em;">
        <div id="map"/>
        {
            if($total-count gt 0) then 
               <div class="hint map pull-right small">
                * This map displays {count($nodes[descendant-or-self::tei:geo])} records. Only places with coordinates are displayed. 
                     <button class="btn btn-default btn-sm" data-toggle="modal" data-target="#map-selection" id="mapFAQ">See why?</button>
               </div>
            else ()
            }
        <script type="text/javascript">
            <![CDATA[      
            var placesgeo = ]]>{geojson:geojson($nodes)}
            <![CDATA[                                                
            leafletMaps(placesgeo)  
            ]]>
        </script>
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
};

(:~
 : Build leafletJS map
:)
declare function maps:build-leaflet-map($nodes as node()*, $total-count as xs:integer?){
    <div id="map-data" style="margin-bottom:3em;">
    
        <script type="text/javascript" src="{$config:nav-base}/resources/leaflet/leaflet.js"/>
        
        <div id="map"/>
        {
            if($total-count gt 0) then 
               <div class="hint map pull-right small">
                * This map displays {count($nodes[descendant-or-self::tei:geo])} records. Only places with coordinates are displayed. 
                     <button class="btn btn-default btn-sm" data-toggle="modal" data-target="#map-selection" id="mapFAQ">See why?</button>
               </div>
            else ()
            }
        <script type="text/javascript">
            <![CDATA[
            //var terrain = L.tileLayer('http://api.tiles.mapbox.com/v3/sgillies.map-ac5eaoks/{z}/{x}/{y}.png', {attribution: "ISAW, 2012"});
            var terrain = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'});
                
            /* Not added by default, only through user control action */
            var streets = L.tileLayer(
                'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', 
                {attribution: "OpenStreetMap"});
                                
            var imperium = L.tileLayer(
                    'https://dh.gu.se/tiles/imperium/{z}/{x}/{y}.png', {
                        maxZoom: 10,
                        attribution: 'Powered by <a href="http://leafletjs.com/">Leaflet</a>. Map base: <a href="https://dh.gu.se/dare/" title="Digital Atlas of the Roman Empire, Department of Archaeology and Ancient History, Lund University, Sweden">DARE</a>, 2015 (cc-by-sa).'
                    });
                                
            var placesgeo = ]]>{geojson:geojson($nodes)}
            <![CDATA[                                
            
                                        
            var geojson = L.geoJson(placesgeo, {onEachFeature: function (feature, layer){
                            var typeText = feature.properties.type
                            var popupContent = 
                                "<a href='" + feature.properties.uri + "' class='map-pop-title'>" +
                                feature.properties.name + "</a>" + (feature.properties.type ? "Type: " + typeText : "") +
                                (feature.properties.desc ? "<span class='map-pop-desc'>"+ feature.properties.desc +"</span>" : "");
                                layer.bindPopup(popupContent);
                     
                                }
                            })
        var map = L.map('map').fitBounds(geojson.getBounds(),{maxZoom: 5});     
        terrain.addTo(map);
                                        
        L.control.layers({
                        "Terrain (default)": terrain,
                        "Streets": streets }).addTo(map);
        geojson.addTo(map);   
        
        ]]>
        </script>
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
};


(:~
 : Build Google maps
:)
declare function maps:build-google-map($nodes as node()*){
    <div id="map-data" style="margin-bottom:3em;">
        <script src="http://maps.googleapis.com/maps/api/js">//</script>
        <div id="map"/>
        <div class="hint map pull-right">* {count($nodes)} have coordinates and are shown on this map. 
             <button class="btn btn-link" data-toggle="modal" data-target="#map-selection" id="mapFAQ">Read more...</button>
        </div>
    
        <script type="text/javascript">
            <![CDATA[
            var map;
                            
            var bounds = new google.maps.LatLngBounds();
            
            function initialize(){
                map = new google.maps.Map(document.getElementById('map'), {
                    center: new google.maps.LatLng(0,0),
                    mapTypeId: google.maps.MapTypeId.TERRAIN
                });

                var placesgeo = ]]>{geojson:geojson($nodes)}
                <![CDATA[ 
                
                var infoWindow = new google.maps.InfoWindow();
                
                for(var i = 0, length = placesgeo.features.length; i < length; i++) {
                    var data = placesgeo.features[i]
                    var coords = data.geometry.coordinates;
                    var latLng = new google.maps.LatLng(coords[1],coords[0]);
                    var marker = new google.maps.Marker({
                        position: latLng,
                        map:map
                    });
                    
                    // Creating a closure to retain the correct data, notice how I pass the current data in the loop into the closure (marker, data)
         			(function(marker, data) {
         
         				// Attaching a click event to the current marker
         				google.maps.event.addListener(marker, "click", function(e) {
         					infoWindow.setContent("<a href='" + data.properties.uri + "'>" + data.properties.name + " - " + data.properties.type + "</a>");
         					infoWindow.open(map, marker);
         				});
         
         
         			})(marker, data);
                    bounds.extend(latLng);
                }
                
                map.fitBounds(bounds);
                // Adjusts zoom for single items on the map
                google.maps.event.addListenerOnce(map, 'bounds_changed', function(event) {
                  if (this.getZoom() > 10) {
                    this.setZoom(10);
                  }
                });
            }

            google.maps.event.addDomListener(window, 'load', initialize)

        ]]>
        </script>
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
};
