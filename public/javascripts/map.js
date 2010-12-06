var map, marker, geoCoder;
function codeAddress(){
    var address = $("#map_address").val();
    geocoder.geocode( { 'address': address}, function(results, status) {
			  if (status == google.maps.GeocoderStatus.OK) {
			      map.setCenter(results[0].geometry.location);
			      var ne = results[0].geometry.viewport.getNorthEast();
			      var sw = results[0].geometry.viewport.getSouthWest();			      
			      map.fitBounds(results[0].geometry.viewport);      
			      
			      var boundingBoxPoints = [
				  ne, new google.maps.LatLng(ne.lat(), sw.lng()),
				  sw, new google.maps.LatLng(sw.lat(), ne.lng()), ne
			      ];
			  } else {
			      alert("Geocode was not successful for the following reason: " + status);
			  }
		      });
 }
function map_initialize(){
    if(typeof google === 'undefined' || $("#map_canvas").length===0){
	return(false);
    }
    var lat, lng, zoom;
    if($("#latitude") && parseInt($("#latitude").val()) > 0){
	lat = $("#latitude").val();	
	zoom = 15;
    }else{
	lat = 23;
	zoom = 5;	
    }	
    if($("#longitude") && parseInt($("#longitude").val()) > 0)
	lng = $("#longitude").val();
    else
	lng = 79;
    var latlng = new google.maps.LatLng(lat, lng);
    geocoder = new google.maps.Geocoder();
    
    var myOptions = {
	zoom: zoom,
	center: latlng,
	mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(document.getElementById("map_canvas"),myOptions);
    marker = new google.maps.Marker({position: latlng, map: map});    
    google.maps.event.addListener(map, 'click', function(event){
				      placeMarker(event.latLng);	    
				  });
}
function map_multiple_markers_initialize(){
    if(typeof google === 'undefined' || $("#map_canvas").length===0 || (typeof marker_objects === "undefined")){
	return(false);
    }
    var zoom;
    var locations = [];
    markers = [];
    var myOptions = {
	zoom: 10,
	mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(document.getElementById("map_canvas"),myOptions);
    var bounds = new google.maps.LatLngBounds();

    marker_objects.forEach(function(marker){			    
			       var loc = new google.maps.LatLng(marker.latitude, marker.longitude);
			       var gmarker = new google.maps.Marker({position: loc, map: map, title: marker.name});
			       bounds.extend(loc);
			       google.maps.event.addListener(gmarker, 'click', function(event){
								 new google.maps.InfoWindow({content: marker.name}).open(map, gmarker);
							     });
			});
    map.fitBounds(bounds);
}
function placeMarker(location){    
    marker.setPosition(location);
    map.setCenter(location);
    $("input#latitude").val(location.lat());
    $("input#longitude").val(location.lng());
}
function loadAPI(){    
    var script = document.createElement("script");
    script.src = "http://www.google.com/jsapi?key=ABQIAAAASgP9ZPn59Iu0JTNFCdiAfhSdz4-UClTyfBQvJsbaUx94ZLstTBS5W9TdTunVVIf0hdAgYavWg43f1w&callback=loadMaps&sensor=false";
    script.type = "text/javascript";
    document.getElementsByTagName("head")[0].appendChild(script);
}
function loadMaps(){
    if(typeof marker_objects==="undefined")
	google.load("maps", "3", {"callback": "map_initialize", other_params:'sensor=false'});
    else
	google.load("maps", "3", {"callback": "map_multiple_markers_initialize", other_params:'sensor=false'});
}