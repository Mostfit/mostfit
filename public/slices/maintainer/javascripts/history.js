$(function() {
    $('.pagination a').click(function(e) {
	// make pagination ajaxy
	var parse_url = /^\/maintainer\/history\?page=(\d+)$/;
	var res = parse_url.exec($(this).attr('href'));
	request_url = '/maintain/history?page='+res[1];
	ajax_call({
	    url: request_url,
	    handler: render
	});
	e.preventDefault();
	return false;
    });
});