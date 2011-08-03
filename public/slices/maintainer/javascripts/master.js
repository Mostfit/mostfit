$(function() {
    setup_ajax_fetch_handlers();
    setup_ajax_forms();
    setup_confirmation_handlers();
   // fix_history_tab_freshness();
    setTimeout(function() { check_if_deployment_possible(); }, 3000);

    $.fn.extend({
	disable : function() { $(this).attr('disabled','disabled'); },
	enable : function() { $(this).removeAttr('disabled'); },
	check : function() { $(this).attr('checked', 'checked'); },
	uncheck : function() { $(this).removeAttr('checked'); },
	select : function() { $(this).attr('selected', 'selected'); }
    });

    // default settings for notifications
    $.notify_osd.setup({
	click_through : false,
	sticky : false,
	dismissable : true,
	timeout : 10
    });
});

function fix_history_tab_freshness() {
    $("ul.tabs li#history").click(function() {
	show_loader();
	ajax_call({
	    url: '/maintain/history',
	    handler: render
	});
    });
}

/* check if deployment is possible */
function check_if_deployment_possible() {
    notify_bottom({text : "Checking deployment status..."});
    ajax_call({
	url: '/maintain/deployment/check_if_deployment_possible',
	handler: function(data) {
            if(data.response == "true")
		notify_bottom({text : "Deployed code in current branch is out of date with the server."});
            else if(data.response == "false")
		notify_bottom({text : "Deployed code in current branch is up-to-date."});
	}
    });
}

function setup_ajax_forms() {
    $("form.ajaxy input[type!=button]").keyup(function(e) {
	if(e.keyCode === 13) // 13 is the key code for the Enter key
	    $(this).parents('form.ajaxy').find('input[name=submit]').click();
    });
    $("form.ajaxy input[name=submit]").click(function(e) {
	var form = $(this).parents('form');
	show_overlay();
	$.notify_osd.create({ text : form.attr('processing'), icon : form.attr('icon'), sticky : true, dismissable : false });
	data = form.serialize();
	ajax_call({
	    url: form.attr("action"),
	    data: data,
	    handler: function(resp) {
		hide_overlay();
		ajax_call({
		    url: form.attr('reload_url'),
		    handler: render
		});
		$.notify_osd.create({ text : form.attr(resp.response) || "An error occurred.", icon : form.attr('icon') || "" });
	    }
	});
	e.preventDefault();
	return false;
    });
}

function setup_confirmation_handlers() {
    $("a.confirm").live('click',function(e) {
	var r = confirm($(this).attr('message') || "Are you sure?");
	var that = this;
	if(r) {
	    show_overlay();
	    data = {};
	    data.extra = {url : $(that).attr('reload_url'), success_text : $(that).attr('success') || "Success.", icon : $(that).attr('icon') || ""};
	    if($(that).attr('callback')) data.extra.callback = $(that).attr('callback');
	    ajax_call({
		url: $(that).attr('url'),
		handler: handle,
		data: data
	    });
	}
	e.preventDefault();
	return false;
    });
}

function setup_ajax_fetch_handlers() {
    $(".ajax-fetch").live('click',function(e) {
	show_loader();
	ajax_call({
	    url: $(this).attr('url'),
	    handler: render
	});
	e.preventDefault();
	return false;
    });
}

/* various event handlers to handle an ajax response sent by ajax_fetch */
function handle(data) {
    hide_overlay();
    if(data.response == "true") {
	(data.arg.success_text) ? $.notify_osd.create({text: data.arg.success_text || "Done.", icon: data.arg.icon || ""}) : $.notify_osd.dismiss();
	if(data.arg.callback)
	    eval(data.arg.callback);
	if(data.arg.url)
	    ajax_call({
		url: data.arg.url,
		handler: render
	    });
    }
    else {
	$.notify_osd.create({text: "An error occurred."});
    }
}
function render(data) {
    $(".tab:visible").html(data.response);
}

/* general function to make an ajax call to 'url', the response to which will be handled by 'handler' ('extra' represents additional information 'handler' may need) */
function ajax_call(params) {
    if(params.handler == render)
	show_loader();
    var xhr = $.ajax({
	url : params.url,
	data : (params.data) ? (params.data) : (""),
	success : function(response) {
	    (params.data && params.data.extra) ? params.handler({response:response, arg:params.data.extra}) : params.handler({response:response});
	},
	error : function() {
	    hide_overlay();
	    $.notify_osd.create({text: "An error occurred."});
	},
	dataType : params.dataType || null
    });
    return xhr; // return xhr object so the request can be aborted later, if needed
}

/* display an ajax loader in the currently active tab */
function show_loader(div) {
    if(div != null)
	$(div).html("<div class='loader'><img src='slices/maintainer/images/progress-dots.gif' /></div>");
    else
	$(".tab:visible").html("<div class='loader'><img src='slices/maintainer/images/progress-dots.gif' /></div>");
}

function notify_bottom(notification) {
    $("#bottom-message-inside span").html(notification.text);
    $("#bottom-message-drawer").show();
}

/* overlay functions */
function show_overlay() {
    $("#overlay").css({'z-index':'890'}).show();
}

function hide_overlay() {
    $("#overlay").css({'z-index':'-1'}).hide();
}