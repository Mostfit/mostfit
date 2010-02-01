// Common JavaScript code across your application goes here.
var lineNos=0;
function spitLogs(){
    $.get("/logs/"+$("div.log_box").attr("id"), function(data){
	    lines = data.split("\n");
	    if(lineNos < lines.length-1){
		for(i=lineNos; i<lines.length-1; i++){
		    $("div.log_box").append(lines[i]+'<br/>');
		}
		lineNos=lines.length-1;
		$("div.log_box").attr({scrollTop: $("div.log_box").attr("scrollHeight") });
	    }
	});
}

function fillOptions(id, select){
    $.ajax({
	    type: "GET",
		dataType: "json",
		url: "/centers/"+id+"/groups.json",
		success: function(data){
		str = "<option value=''>Select the group for this person</option>";
		for(i=0; i < data.length; i++){
		    str += "<option value=\"" + data[i]["id"] + "\">" + data[i]["name"] + "</option>";
		}
		$("#client_group_id").find("form").remove();
		$("#client_group_id").html(str).val(select);
	    }
	});
}
function fillCode(center_id, group_id){
    $.ajax({
	    type: "GET",
	    dataType: "json",
	    url: "/centers/"+center_id+"/groups/"+group_id+".json",
	    success: function(data){
		$("#client_reference").val(data["code"]);
	    }
	});
}
function setToggleText(){
    $("table.report tr td a").each(function(){
	    if($(this).parent().parent().next().css("display")!="none"){
		$(this).text($(this).text().replace('Expand', 'Collapse'));
		$(this).addClass('collapse');
		$(this).removeClass('expand');
	    }else{
		$(this).text($(this).text().replace('Collapse', 'Expand'));
		$(this).addClass('expand');
		$(this).removeClass('collapse');
	    }
	});
}
$(document).ready(function(){
	//Handling reports
	if($("table.report").length>0){
	    $("table.report tr").hide();
	    $("table.report tr.branch").show();
	    $("table.report tr.branch_total").show();
	    $("table.report tr.header").show();
	    $("table.report").before("<a class='expand_all'>Expand all</a>");
	    $("table.report tr.branch td").append("<a id='center' class='expand'>Expand centers</a>");
	    $("table.report tr.center td").append("<a id='group' class='expand'>Expand groups</a>");
	    if($("table.report tr.date").length>0)
		$("table.report tr.group td").append("<a id='date' class='expand'>Expand dates</a>");
	    if($("table.report tr.loan").length>0)
		$("table.report tr.group td").append("<a id='loan' class='expand'>Expand loans</a>");
	    $("a.expand_all").click(function(){		    
		    $("table.report tr").show();
		    setToggleText();
		});
	    $("table.report tr td a").click(function(){
		    action=$(this).attr("class").trim();
		    child_type=$(this).attr("id");
		    child_type_total=child_type+"_total";
		    parent_type = $(this).parent().parent().attr("class");
		    parent_type_total=parent_type+"_total";
		    if(action==="expand"){
			$(this).parent().parent().nextUntil("tr."+parent_type).filter("tr."+child_type).show();
			$(this).parent().parent().nextUntil("tr."+parent_type).filter("tr."+child_type_total).show();
		    }else{
			$(this).parent().parent().nextUntil("tr."+parent_type_total).hide();
			$(this).parent().parent().nextUntil("tr."+parent_type_total).hide();
		    }
		    if(parent_type=="branch" && action=="collapse")
			$(this).parent().parent().nextUntil("tr.branch_total").hide();		    
		    setToggleText();
		});	    
	}
	if($("a.moreinfo").length>0){
	    $("a.moreinfo").click(function(){
		    path="/"+$(this).attr("id").split("_").join("/");
		    $("a.moreinfo").append("<img id='spinner' src='/images/spinner.gif'>");
		    $("table.moreinfo").remove();
		    $.get(path, function(data){
				$("a.moreinfo").after("<a class='lessinfo'>Less info about this branch</a>").after(data);
				$("a.moreinfo").hide();
				$("img#spinner").remove();
				$("a.lessinfo").click(function(){
					$("a.moreinfo").show();
					$("table.moreinfo").remove();
					$("a.lessinfo").remove();
				    });				
			    });
		});
	}
	if($('#mfi_color') && $('#mfi_color').length>0){
	    $('#mfi_color').colorPicker();
	}
	$(document).shortkeys({
		'n': function(){alert('foo');}
	    });
	$('.delete').click(function() {
		var answer = confirm('Are you sure?');
		return answer;
	    }); 
	if(window.location.pathname.indexOf("edit")===-1){
	    $("#client_group_id").change(function(){
		    fillCode($("#client_center_id").val(), $("#client_group_id").val());
		});
	}
	if($("div.log_box").length>0){
	    setInterval(function(){
		    spitLogs();
		}, 2000);
	}
	$("#new_client_group_link").click(function(){
		id=$("#client_center_id option:selected").val();
		$.ajax({
			type: "get",
			url: "/data_entry/groups/new?center_id="+id,
			success: function(data){
			    $("#new_client_group_form").html(data);
			    $("#new_client_group_form").submit(function(){
				    $.ajax({
					    type: "POST",
					    dataType: "json",
					    url: "/data_entry/groups/create",
					    data: "client_group[name]="+$("#client_group_name").val()
						+ "&client_group[number_of_members]=" + $("#client_group_number_of_members").val()
						+ "&client_group[center_id]=" + $("#client_center_id").val()
						+ "&client_group[code]=" + $("#client_group_code").val(),
					    success: function(){
						$("#client_group_name").val();
						fillOptions($("#client_center_id").val(), $("#client_group_name").val());
						$("#new_client_group_form").html("");
					    },
					    error: function(data){
						alert(data.responseText);
					    }
					});
				    return false;
				});
			}
		    });
	    });
	if($("#client_center_id")){
	    $("#client_center_id").change(function(){
		    $(this).find("option:selected").each(function () {
			    id=$(this).val();
			    if(id>0){
				$("#new_client_group_link").css("display", "block");
				fillOptions(id);
			    }else{
				$("#new_client_group_link").css("display", "none");
				$("#client_group_id").find("form").remove();
			    }
			});
		});
	}
    });
