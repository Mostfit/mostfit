$(function() {
    $("#time-section table input[type=radio]").change(function() { setup_select_enabler($(this).parent()) });

    $("#schedule-custom").hide();
    $("input[name=schedule-type]").change(function() {
	var schedule_type = $("input[name=schedule-type]:checked").val();
	$("[id^=schedule]").not("#schedule-type").hide();
	$("#schedule-"+schedule_type).show();
    });

    if($("#task-data").length > 0)
	preselect_task_schedule();

    function preselect_task_schedule() {
	var components = ["minute", "hour", "day", "month", "weekday"];
	var i = 0;
	var component_values = [];
	var simple_components = {
	    'hourly'  : ['0','*','*','*','*'],
	    'daily'   : ['0','0','*','*','*'],
	    'weekly'  : ['0','0','*','*','0'],
	    'monthly' : ['0','0','1','*','*']
	};
	for(i=0; i<components.length; i++) {
            component_values[i] = $("#task-data input.component[name="+components[i]+"_data]").val();
	}

	// if the schedule is "simple", select the appropriate choice from the simple schedules dropdown
	var schedule_is_simple = false;
	for(var simple_component in simple_components) {
	    if(simple_components.hasOwnProperty(simple_component)) {
		simple_component_value = simple_components[simple_component];
		if(compareArrays(component_values, simple_component_value)) {
		    schedule_is_simple = true;
		    $("select[name=schedule-simple] option[value="+simple_component+"]").select();
		}
	    }
	}

	console.log(component_values);
	// otherwise, the schedule is complex, so select that
	if(!schedule_is_simple && !compareArrays(component_values,[])) {
	    $("#schedule-type input[type=radio][value=custom]").check();
	    $("#schedule-simple").hide();
	    $("#schedule-custom").show();
	    for(i=0; i<components.length; i++) {
		component_value = component_values[i];
		if(component_value && component_value != "*") {
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
    }

    function setup_select_enabler(el) {
	if(el.children(".select-enabler:checked").length == 0)
            el.children("select").disable();
	else
            el.children("select").enable();
    }
});

function compareArrays(a,b) {
    if(a.length != b.length) return false;
    for(i=0; i<a.length; i++)
	if(a[i] !== b[i]) return false;
    return true;
}