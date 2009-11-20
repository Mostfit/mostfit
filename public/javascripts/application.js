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
$(document).ready(function(){
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
    