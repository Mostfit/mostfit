$(function() {
	$("table td input.select").click(function() {
		var parent = $(this).parent();
		var selection_ids = parent.find("select.remaining").val();
		for(var i = 0; i < selection_ids.length; i++) {
		    var selection = parent.find("select.remaining option[value="+selection_ids[i]+"]")
		    parent.find("select.current").append(selection[0]);
		}
	});

	$("table td input.deselect").click(function() {
		var parent = $(this).parent();
		var deselection_ids = parent.find("select.current").val();
		for(var i = 0; i < deselection_ids.length; i++) {
		    var deselection = parent.find("select.current option[value="+deselection_ids[i]+"]")
		    parent.find("select.remaining").append(deselection[0]);
		}
	});

	$("input[type=submit]").click(function(e) {
		$("select.current option").attr("selected", "selected");
		//		e.preventDefault();
		// return false;
	});
});