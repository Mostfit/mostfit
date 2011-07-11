$(function() {
    setup_snapshot_form_handler();
});

function setup_snapshot_form_handler() {
    $("#take-snapshot form input").live('click',function(e) {
	show_overlay();
	$.notify_osd.new({text: "Saving snapshot...", icon:"slices/maintainer/images/database.png", sticky: true, dismissable: false});
	ajax_call({
	    url: '/maintain/database/take_snapshot',
	    handler: handle,
	    data: {
		extra: {
		    url : '/maintain/database',
		    success_text : 'Snapshot saved.',
		    icon : 'slices/maintainer/images/database.png',
		    callback : 'hide_overlay()'
		}
	    }
	});
	e.preventDefault();
	return false;
    });
}