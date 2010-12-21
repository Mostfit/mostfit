var map, marker, geoCoder, setZoom;
var dayColors = {'monday': 'blue', 'tuesday': 'brown', 'wednesday': 'violet', 'thursday': 'magenda', 'friday': 'black', 'saturday': 'red'};
var branchColors = ['blue', 'brown', 'violet', 'magenda', 'black', 'red'];
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
    var locations = [];
    markers = [];
    var myOptions = {
	zoom: 10,
	mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(document.getElementById("map_canvas"),myOptions);
    var bounds = new google.maps.LatLngBounds();
    var infoWindow = new google.maps.InfoWindow({'maxWidth': 200});
    var counter = 0;
    marker_objects.forEach(function(marker){
			       var loc = new google.maps.LatLng(marker.latitude, marker.longitude);			       
			       var zindex, color, letter, icon_url;
			       if(marker.type){
				   if(marker.type === "center" && daywise===true){
				       zindex = marker.meeting_order;
				       color=dayColors[marker.meeting];
				       letter=marker.meeting_order;
				   }else if(marker.type=="center"){
				       zindex = marker.meeting_order;
				       letter="C";
				       if(marker.due || marker.paid){
					   if(marker.due>0)
					       color="red";
					   else
					       color="green";
				       }else{
					   color="brown";
				       }					   
				   }else{
				       zindex = 100;
				       letter = marker.type[0].toUpperCase();
				       color="green"; 
				   }
				   icon_url = "/images/map_icons/"+color+"/" + letter + ".png";
				   var gmarker = new google.maps.Marker({position: loc, map: map, title: marker.name, flat: true, icon: icon_url, zIndex: zindex});
			       }else{
				   var gmarker = new google.maps.Marker({position: loc, map: map, title: marker.name, flat: true});
			       }				   
			       bounds.extend(loc);
			       google.maps.event.addListener(gmarker, 'click', function(event){
                                                                 var str ="<div class='infobox'><b>" + marker.type + "</b>: " + marker.name;
								 if(marker.type === "center"){
								     if(marker.branch)
									 str += "<br/><b>Branch</b>: " + marker.branch;
								     if(marker.due)
									 str += "<br/><b>Due</b>: " + marker.due;
								     if(marker.paid)
									 str += "<br/><b>Paid</b>: " + marker.paid;
								     str += "<br/><b>meeting time: </b>" + marker.meeting + " at " + marker.time+"</div>";
								 }
								 infoWindow.setContent(str);
								 infoWindow.open(map, gmarker);
							     });
			});
    map.fitBounds(bounds);
    setZoom = map.getZoom();
}
function placeMarker(location){    
    marker.setPosition(location);
    map.setCenter(location);
    $("input#latitude").val(location.lat());
    $("input#longitude").val(location.lng());
}
function loadAPI(){    
    var script = document.createElement("script");
    // need to more this key to some place like constants.
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
function centerMap(){
    if(typeof google != 'undefined' && $("#map_canvas")){
	if(marker){
	    google.maps.event.trigger(map, 'resize');	    
	    map.setCenter(marker.position);	    
	}
	else{
	    map_multiple_markers_initialize();	    
	}
	$("#map_canvas").css('height', '400').css('width', '400');
    }    
}
