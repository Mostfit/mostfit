$(function() {
    setup_ajax_forms();

    var xhr;

    $("#logs #input select, #logs #input input").change(function() {
	if(xhr != null)
	    xhr.abort();
	var file = $("#logs #input select[name=file]").val();
	var max_line_count = $("#logs #input input[name=max_line_count]").val();
	if(file == "none")
	    return false;
	get_log(file, max_line_count, true);
    });

    function get_log(file, max_line_count, is_first_request) {
	if(is_first_request) show_loader("#logs #log");
	xhr = ajax_call({
	    url: "/maintain/logs/get",
	    data: {
		file : file,
		max_line_count : max_line_count,
		is_first_request : is_first_request
	    },
	    handler: function(resp) {
		$("#logs #log").html('');
		for(var i=0; i<resp.response.length; i++)
		    $("#logs #log").append("<p>"+resp.response[i]+"</p>");
		get_log(file, max_line_count, false);
	    },
	    dataType: 'json'
	});
    }
});