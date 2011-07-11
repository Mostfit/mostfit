(function($) {
    var notif_obj;
    var defaults = {
	text             : '',
	icon             : '',
	timeout          : 5,
	sticky           : false,
	dismissable      : false,
	click_through    : true,
	buffer           : 40,
	opacity_max      : 0.85,
	opacity_min      : 0.20,
    };
    
    $.notify_osd = {
	defaults : defaults,
	new : function(options) {
	    var opts = $.extend({}, defaults, options);
	    var mouse, notification, buffer;

	    var Point = function(x,y) {
		return {
		    x : x,
		    y : y,
		    lies_inside     : function(region) {
			return ((this.y > region.top) && (this.y < region.bottom) && (this.x > region.left) && (this.x < region.right));
		    },
		    min_distance_in : function(region) {
			var rel_position = {
			    top    : Math.abs(this.y - region.top),
			    right  : Math.abs(this.x - region.right),
			    bottom : Math.abs(this.y - region.bottom),
			    left   : Math.abs(this.x - region.left)
			};
			var min = rel_position.left;
			if(rel_position.top < min)      min = rel_position.top;
			if(rel_position.right < min)    min = rel_position.right;
			if(rel_position.bottom < min)   min = rel_position.bottom;
			return min;
		    },
		    to_string      : function() { return "x: "+this.x+" y: "+this.y; }
		};
	    };

	    var Region = function(data) {
		return {
		    top    : data.top,
		    left   : data.left,
		    width  : data.width,
		    height : data.height,
		    bottom : data.top + data.height,
		    right  : data.left + data.width,
		    to_string : function() { return "t: "+this.top+" l: "+this.left+" h: "+this.height+" w: "+this.width; }
		};
	    };

	    if($('.notify-osd').length == 0) {
		notif_obj = $('<div class="notify-osd"><div><table><tr><td class="notify-osd-content">'+opts.text+'</td></tr></table></div></div>').css({
		    'opacity' : opts.opacity_max
		}).hide().appendTo('body');
	    }
	    else {
		notif_obj = $('.notify-osd');
	    }

	    notif_obj.extend({
		opts : opts,
		set_text : function(text) {
		    $(this).find('.notify-osd-content').html(text);
		    return this;
		},
		set_icon : function(src) {
		    if(src != '')  $(this).find('tr').prepend_or_replace('<td class="notify-osd-icon"><img src="'+src+'" /></td>','.notify-osd-icon');
		    else           $(this).find('.notify-osd-icon').remove();
		    return this;
		},
		set_dismissable : function(dismissable) {
		    if(opts.dismissable) {
			$(this).children('div').append_or_replace('<a href="#" class="notify-osd-dismiss" title="Dismiss">x</a>','.notify-osd-dismiss');
			$(".notify-osd-dismiss").unbind('click').click(function() {
			    notif_obj.dismiss();
			});
		    }
		    else {
			$(this).find('.notify-osd-dismiss').remove();
		    }
		    return this;
		},
		set_click_through : function(click_through) {
		    $('.clone').remove();
		    if(click_through) {
			$('a,input').not('.notify-osd-dismiss').each(function() {
			    var link = {
				top_left     : new Point( $(this).offset().left                   , $(this).offset().top                    ),
				top_right    : new Point( $(this).offset().left + $(this).width() , $(this).offset().top                    ),
				bottom_right : new Point( $(this).offset().left + $(this).width() , $(this).offset().top + $(this).height() ),
				bottom_left  : new Point( $(this).offset().left                   , $(this).offset().top + $(this).height() )
			    };
			    if(link.top_left.lies_inside(notification) || link.top_right.lies_inside(notification) || link.bottom_right.lies_inside(notification) || link.bottom_left.lies_inside(notification)) {
				$(this).clone(true,true).addClass('clone').appendTo('body').css({
				    'position' : 'absolute',
				    'top'      : $(this).offset().top,
				    'left'     : $(this).offset().left,
				    'height'   : $(this).height(),
				    'width'    : $(this).width(),
				    'opacity'  : '0',
				    'z-index'  :'950'
				});
			    }
			});
		    }
		},
		show : function() {
		    this.set_text(opts.text).set_icon(opts.icon).set_dismissable(opts.dismissable);
		    
		    $(this).fadeIn('fast',function(){
			notification = new Region({
			    top    : notif_obj.offset().top,
			    left   : notif_obj.offset().left,
			    width  : notif_obj.width(),
			    height : notif_obj.height()
			});
			buffer = new Region({
			    top    : notification.top    - opts.buffer,
			    left   : notification.left   - opts.buffer,
			    width  : notification.width  + 2 * opts.buffer,
			    height : notification.height + 2 * opts.buffer
			});
			clearTimeout(this.timeout);
			this.timeout = (!opts.sticky && opts.timeout) ? setTimeout(function() { notif_obj.dismiss(); },opts.timeout*1000) : null;
			mouse = new Point(0, 0);

			notif_obj.set_click_through(opts.click_through);

			$(document).mousemove(mousemove);
		    });
		    return this;
		},
		dismiss : function() {
		    $(document).unbind('mousemove');
		    $(this).fadeOut('fast',function() {
			$(this).remove();
			$('.clone').remove();
		    });
		}
	    });

	    var mousemove = function(e) {
		mouse.x = e.pageX - $('body').scrollLeft();
		mouse.y = e.pageY - $('body').scrollTop();
		var opacity;
		if(mouse.lies_inside(buffer)) {
		    // find the minimum distance of the mouse from the edges of the buffer region
		    min_distance = mouse.min_distance_in(buffer);
		    if(mouse.lies_inside(notification))
			opacity = opts.opacity_min;
		    else
			opacity = opts.opacity_max - (opts.opacity_max-opts.opacity_min) * (min_distance/opts.buffer);
		}
		else {
		    opacity = opts.opacity_max;
		}
		notif_obj.css('opacity', opacity);
	    }

	    $(document).unbind('mousemove');
	    if(notif_obj.css('display') != 'none') {
		notif_obj.fadeOut('fast',function() {
		    notif_obj.show();
		});
	    }
	    else {
		notif_obj.show();
	    }

	    return notif_obj;
	},
	setup : function(options) {
	    defaults = $.extend({}, defaults, options);
	},
	dismiss : function() {
	    notif_obj.dismiss();
	}
    };

    $.fn.extend({
	prepend_or_replace : function(html,selector) {
	    if($(this).children(selector).length > 0)
		$(this).children(selector).remove();
	    return $(this).prepend(html);
	},
	append_or_replace : function(html,selector) {
	    if($(this).children(selector).length > 0)
		$(this).children(selector).remove();
	    return $(this).append(html);
	}
    });
})(jQuery);
