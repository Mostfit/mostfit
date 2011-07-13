$(function() {
    $("#files select").change(function() {
	var file = $(this).val();
	if(file == "none") return false;
	get_log(file, true);
    });
    // setTimeout(function() { get_log(true) }, 2000);
});

function get_log(file, is_first_request) {
    if(is_first_request) show_loader("#logs #log");
    ajax_call({
	url: "/maintain/logs/get",
	data: {
	    file : file,
	    is_first_request : is_first_request
	},
	handler: function(resp) {
	    $("#logs #log").html('');
	    for(var i=0; i<resp.response.length; i++)
		$("#logs #log").append("<p>"+resp.response[i]+"</p>");
	    get_log(file, false);
	},
	dataType: 'json'
    });
}