$(function() {
    setup_ajax_forms();

    var result_table = $("#result table");
    var result_table_body = result_table.find("tbody");
    var form = $("form");

    result_table.hide();

    form.find("input[type=button]").click(function(e) {
	var metric = form.find("select[name=metric]").val();
	var day_of_month = form.find("select[name=day_of_month]").val();
	if(metric === "none" || day_of_month === "none") {
	    return false;
	}
	else {
	    show_overlay();
	    $.notify_osd.create({
		text : 'Fetching '+form.find("select[name=metric] option:selected").html().toLowerCase()+' for day '+day_of_month+' of every month...',
		sticky : true,
		icon : 'slices/maintainer/images/gears.png'
	    });
	    ajax_call({
		url: "/maintain/billing/get",
		data: {
		    metric: metric,
		    day_of_month: day_of_month,
		},
		handler: function(resp) {
		    result_table_body.find("tr").remove();
		    var response = resp.response;
		    for(var i=0; i<response.length; i++) {
			var row = $("<tr>").append("<td><td>");
			row.find("td:first").html(response[i].date);
			row.find("td:last").html(response[i].count);
			row.appendTo(result_table_body);
		    }
		    result_table.show();
		    $.notify_osd.dismiss();
		    hide_overlay();
		},
		dataType: 'json'
	    });
	}
	
	e.preventDefault();
	return false;
    });
});