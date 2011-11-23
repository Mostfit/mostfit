$(function() {
	$("#add").click(function() {
	  var selection_ids = $('#select-from').val();
		for(var i = 0; i < selection_ids.length; i++) {
		  var selection = $("#select-from option[value="+selection_ids[i]+"]");
		  $('#select-to').append(selection[0]);
		}
	});

	$("#remove").click(function() {
		var deselection_ids = $('#select-to').val();
		for(var i = 0; i < deselection_ids.length; i++) {
		    var deselection = $("#select-to option[value="+deselection_ids[i]+"]")
		    $('#select-from').append(deselection[0]);
		}
	});

	$("input[type=submit]").click(function(e) {
		$("select.current option").attr("selected", "selected");
		//		e.preventDefault();
		// return false;
	});
});