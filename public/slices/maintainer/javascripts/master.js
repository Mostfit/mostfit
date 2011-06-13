$(function() {
    setup_snapshot_form_handler();
    setup_ajax_fetch_handler();

    $.fn.extend({
	disable : function() { $(this).attr('disabled','disabled'); },
	enable : function() { $(this).removeAttr('disabled'); },
	check : function() { $(this).attr('checked', 'checked'); },
	uncheck : function() { $(this).removeAttr('checked'); },
	select : function() { $(this).attr('selected', 'selected'); }
    });
});

function preselect() {
    var components = ["minute", "hour", "day", "month", "weekday"];
    var i = 0;
    for(i=0; i<5; i++) {
	component_value = $("#task-data input.component[name="+components[i]+"_data]").val();
	if(component_value != "*") {
	    var el = $("#"+components[i]+"s");
	    el.find("input[type=radio]:first").uncheck();
	    el.find("input.select-enabler").check();
	    setup_select_enabler(el);
	    
	    values = component_value.split(",");
	    el.find("option").each(function() {
		if($.inArray($(this).val(), values) != -1)
		    $(this).select();
	    });
	}
    }
}

function setup_select_enabler(el) {
    if(el.children(".select-enabler:checked").length == 0)
	el.children("select").disable();
    else
	el.children("select").enable();
}

function setup_ajax_fetch_handler() {
    $(".ajax-fetch").live('click',function(e) {
	show_loader($(".tab:visible"));
	$.ajax({
	    url : $(this).attr('url'),
	    success : function(response) {
		render(response);
	    },
	    error : function() {
		notify({text: "Something went wrong. Please try again after sometime.", dismissable: true});
	    }
	});
	e.preventDefault();
	return false;
    });
}

function setup_snapshot_form_handler() {
    $("#take-snapshot form input").live('click',function(e) {
	notify({text: "Saving snapshot...", dismissable: false});
	$.ajax({
	    url : '/maintain/database/take_snapshot',
	    success : function(successful) {
		if(successful == "true")
		    window.location.reload();
		else if(successful == "false")
		    notify({text: "Snapshot could not be saved.", dismissable: true});
	    },
	    error : function() {
		notify({text: "Error in saving snapshot.", dismissable: true});
	    }
	});
	e.preventDefault();
	return false;
    });
}

/* ajax loader and rendering functions */
function show_loader(div) {
    div.html("<div class='loader'><img src='slices/maintainer/images/progress-dots.gif' /></div>");
}
function render(content) {
    $(".loader").parent().html(content);
}

/* notification functions */
function dismiss_notification() {
    $("#message-inside span").html("");
    $("#message-drawer").hide();
    $("#overlay").css({'z-index':'-1'}).hide();
    $("#message-inside .dismiss").remove();
    return false;
}

function notify(notification) {
    if($("#message-drawer:visible").length > 0) {
	dismiss_notification();
    }
    $("#message-inside span").html(notification.text);
    $("#message-drawer").show();
    if(notification.dismissable)
	make_dismissable();
    else
	$("#overlay").css({'z-index':'998'}).show();
}

function make_dismissable() {
    $("#message-inside").append("<a class='dismiss' href='"+window.location.hash+"' onclick='dismiss_notification()'>x</a>");
}