// Common JavaScript code across your application goes here.
var lineNos=0;
function addFloater(link){
    $(link).after("<div class='floater'><img height='400' src="+link.attr('href')+"/><span class='close_button'>X</span></div>");	  
    $(".close_button").click(function(button){
	    $("div.floater").remove();
	});
}
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
function showThis(li, idx){
    $("div.tab_container div.tab").hide();
    $("div.tab_container ul.tabs li.active").removeClass("active");
    $(li).addClass("active");
    tab = $($("div.tab_container div.tab")[idx]).show();
    remote = $(tab).find("input:hidden");
    if(remote.length>0 && remote.attr("name")=="_load_remote"){
	$.ajax({
               url: remote.val(),
	       success: function(data){
		   $($("div.tab_container div.tab")[idx]).html(data);
		   create_remotes();
		},
		beforeSend: function(){
		    $('#spinner').show();
		},
		error: function(xhr, text, errorThrown){
		    txt = "<div class='error'>"+xhr.responseText+"</div>"
		    $($("div.tab_container div.tab")[idx]).html(txt);
		},
		complete: function(){
		    $('#spinner').hide();
		}
	    }
	);
	remote.remove();
    }
    window.location.hash=$(li).attr("id");
}
function showTableTrs(){
    $("table.report tr").hide();
    $("table.report tr.branch").show();
    $("table.report tr.branch_total").show();
    $("table.report tr.org_total").show();
    $("table.report tr.header").show();
}
function daysInMonth(month, year){
    isLeap = false;
    if ((year%4 == 0 && year%100 != 0)||year%400 == 0) isLeap = true;
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) days = 31;
    if (month == 4 || month == 6 || month == 9 || month == 11) days = 30;
    if (month == 2 && isLeap) days = 29;
    if (month == 2 && isLeap == false) days = 28;
    return days;
}

function dateFromAge(ageYear, ageMonth, ageDay){
    $('#age_year_field').removeClass('error');
    $('#age_month_field').removeClass('error');
    $('#age_day_field').removeClass('error');
    var birthDate = new Array();
    today = new Date();

    todayDay = today.getDate();
    todayMonth = today.getMonth()+ 1;
    todayYear = today.getFullYear();
    if(!ageDay)
	ageDay=0;
    if(!ageMonth)
	ageMonth=0;
    if(!ageYear)
	ageYear=0;
    var returnEarly;
    if (ageMonth > 11 || ageMonth < 0){
	$('#age_month_field').addClass('error');
	returnEarly = true;
    }
    if (ageDay > 31 || ageDay < 0){
	$('#age_day_field').addClass('error');
	returnEarly = true;
    }

    if (returnEarly) return false;

    if(ageDay < todayDay){
	if (ageMonth < todayMonth){
	    birthDate[1] = todayMonth - ageMonth;
	    birthDate[0] = todayYear - ageYear;
	}
      else{
	  birthDate[1] = todayMonth - ageMonth + 12;
	  birthDate[0] = todayYear - ageYear - 1;
      }
    }
    else{
	if (ageMonth < todayMonth -1){
	    birthDate[1] = todayMonth - ageMonth -1 ;
	    birthDate[0] = todayYear - ageYear;
	}
	else{
	    birthDate[1] = todayMonth - ageMonth + 12 -1 ;
	    birthDate[0] = todayYear - ageYear - 1 ;
	}
    }

    days = daysInMonth(birthDate[1], birthDate[0]);

    if(ageDay < todayDay){
	birthDate[2] = todayDay - ageDay;
    }
    else{
	birthDate[2] = days + todayDay - ageDay;
    }
    return birthDate;
}
function create_remotes(){
    $("a._remote_").click(function(){
	    href=$(this).attr("href");
	    method="GET"
	    if($(this).hasClass("self")){
		href=href+(href.indexOf("?")>-1 ? "&" : "?")+$(this).parent().serialize();
                method="POST"
	    }
	    a=$(this);
	    $.ajax({
		    type: "POST",
		    url: href,
		    success: function(data){
			$(a).after(data);
			$(a).remove();
		    },
		    error: function(xhr, text, errorThrown){
			txt = "<div class='error'>"+xhr.responseText+"</div>"
			$(a).after(txt);
		    }
		});
	    return false;
	});

    $("a._customreports_").click(function(){
	    href=$(this).attr("href");
	    method="GET"
	    if($(this).hasClass("self")){
		href=href+(href.indexOf("?")>-1 ? "&" : "?")+$(this).parent().serialize();
                method="POST"
	    }
	    a=$(this);
	    $.ajax({
		    type: "POST",
		    url: href,
		    success: function(data){
			$(a).after(data);
			$(a).remove();
      attachCustomTableEvents();
		    },
		    error: function(xhr, text, errorThrown){
			txt = "<div class='error'>"+xhr.responseText+"</div>"
			$(a).after(txt);
		    }
		});
	    return false;
	});

    $("form._remote_").submit(function(){
	    form = $(this);
	    $(form).after("<img id='spinner' src='/images/spinner.gif' />");
	    $.ajax({
		    type: form.attr("method"),
		    url: form.attr("action"),
		    data: form.serialize(),
		    success: function(data){
			if(form.find("div").length>0)
			    form.find("div").html(data);
			else if(form.find("table").length>0){
			    form.find("table").html(data);
			}else if(form.find("input[name='_target_']").length>0){
			    id=form.find("input[name='_target_']").attr("value");
			    $("#"+id).html(data);
			}
			$("#spinner").remove();
		    },
		    error: function(xhr, text, errorThrown){
			$("div.error").remove();
			txt = "<div class='error'>"+xhr.responseText+"</div>"
			form.before(txt);
			$("#spinner").remove();			
		    }
		});
	    return false;
	});
}
function attachReportingFormEvents(id){
    $("#reporting_form tr#"+id+" select").change(function(){
	  if($(this).attr("class")=="more")
	      return;
	  var types = ["model", "property", "operator", "span"];
	  id = $(this).attr("id");
	  name = $(this).attr("name").split(/\[/)[0];
	  counter = $(this).attr("name").split(/\[/)[1].split("]")[0];

	  $(this).find("option:selected").each(function(){
		  for(i=types.indexOf(name)+1; i<=types.length; i++){
		      $("#reporting_form select#"+types[i]+"_"+counter).html("");
		  }
		  nextType = types[types.indexOf(id.split('_')[0])+1];
		  $.ajax({
			url: "/search/get?counter="+counter+"&"+$("#reporting_form").serialize(),
			success: function(data){
                              if(nextType==="span"){
				  $("#reporting_form span#"+nextType+'_'+counter).html(data);				  
			      }else{
				  $("#reporting_form select#"+nextType+'_'+counter).html("");
				  $("#reporting_form select#"+nextType+'_'+counter).append(data);
			      }
			  }
		    });
	      });
      });
  $("#reporting_form tr#"+id+" select.more").change(function(){
	  var type = $(this);
	  var counter = parseInt($(this).attr("name").split(/\[/)[1].split("]")[0]);
	  if($("#reporting_form select#model_"+counter).length>0){
	      model=$("#reporting_form select#model_"+counter).val();
	  }else if($("#reporting_form input#model_"+counter).length>0){
	      model=$("#reporting_form input#model_"+counter).attr("value");
	  }else{
	      model=$("#reporting_form select#model_1").val();
	  }
	  $.ajax({
		  url: "/search/reporting?counter="+(counter+1)+"&model="+model+"&more="+type.val(),
		  success: function(data){
		      $("tr#formdiv_"+(counter+1)).unbind().remove();
		      $("tr#formdiv_"+(counter)).after(data);
		      attachReportingFormEvents("formdiv_"+(counter+1));
		  }
	      });
      });
}

//For Rules Engine
total_fields = 0;
total_conditions = 0;

//For Rules Engine
function cleanUpFields(type, id) {//used in rules form
  for(i=Number(id)+1; i<total_fields; i++) {
    $("#"+type+"_select_"+i).remove();
    $("#"+type+"_selectcomparator_"+i).remove();
    $("#"+type+"_selectbinaryoperator_"+i).remove();
    $("#"+type+"_selectboolean_"+i).remove();
    $("#"+type+"_selectvalue_"+i).remove();
    $("#"+type+"_selectmore_"+i).remove();
    $("#"+type+"_textfield_"+i).remove();
    $("#"+type+"_date_"+i).datepicker("destroy");
    $("#"+type+"_date_"+i).remove();
    $("#"+type+"_hidden_"+i).remove();
  }
}

//For Rules Engine
function attachRulesFormEvents(type, id) {//type = {"condition", "precondition"}
  if(id == 0) {
    $("#select_0"/*name of the model*/).change(function() {
	  	  $.ajax({
		  	url: "/rules/get?id=1"+"&type="+type+"&for="+document.getElementById("select_0").value+"&condition_id=1&variable_id=1&return_only_models=true",
			  success: function(data){
            $("#"+type+"_select_1").replaceWith(data);
            cleanUpFields(type,1);
            attachRulesFormEvents(type,1);
			    }
  		    });
        });
  }

  $("#"+type+"_select_"+id).change(function() {
//      alert("called")
      if(id+1> total_fields)
        total_fields = id+10;//delete some more fields than id+1 since sometimes more than 1 field is returned per request(there is no harm is deleting extra fields anyways)
      if(id == 0)
        return;//special case to handle that
      parent_div_id = document.getElementById(type+"_select_"+id).parentNode.id;//it is of type c1v2=> condition 1, variable 2 
      condition_id = Number(parent_div_id.substr(1,1));//now this is with assumption that condition_id is single digit (can there be more than 9 conditions ever? if that happens this code fails)
      variable_id = Number(parent_div_id.substr(3,1));//since we have only two variables per condition, variable_id will be single digit
      prev_field = document.getElementById(type+"_select_"+(Number(id)-1));
      if(prev_field == null)//this happens for first select of every extra condition
        prev_field = document.getElementById("select_0");
      $.ajax({
      url: "/rules/get?for="+document.getElementById(type+"_select_"+id).value+
          "&type="+type+
          "&id="+(Number(id)+1)+"&prev_field="+prev_field.value+
          "&condition_id="+condition_id+/*name of div boxes are c1v1, c2v1 ... where the firstnumber refers to condition_id and second to variable number local to that condition*/
          "&variable_id="+variable_id+
          "&return_only_models=true"
      ,success: function(data) {
          cleanUpFields(type,id);
          $("#"+type+"_select_"+id).after(data);
          if(data.indexOf("<select") != -1) {
            attachRulesFormEvents(type,Number(id)+1);
            last_accessed_id = Number(id)+1;
          }
          if(data.indexOf("selectmore_") != -1) 
            attachRulesFormEventsForSelectMoreField(type, Number(id)+3, condition_id);
          //alert(data);
          return true;
        }
        });
      return true;
      });
}

//For Rules Engine
function getDiv(divId, div_container) {
      div1 = document.getElementById(divId);
      if(div1 != null)
        return div1;

      div1 = document.createElement('div');
      div1.id = divId;
      div_container.appendChild(div1);
      return div1;
}

//For Rules Engine
function attachRulesFormEventsForSelectMoreField(type, id, condition_id) {
  condition_id = Number(condition_id)+1; //tis generates the new condition id whichwe are going to add
  $('#'+type+'_selectmore_'+id).change(function() {
      //alert(id+" "+condition_id);
      val = document.getElementById(type+"_selectmore_"+id).value;
      //alert(val);
      if((val == "and") || (val == "or")) {
        var div1;
        if(type == "condition")
          div1 = getDiv("c"+condition_id, document.getElementById("conditions_container"));
        else {
          div1 = getDiv("p"+condition_id, document.getElementById("preconditions_container"));
          }
        //new_select = document.getElementById(type+"_select_1").cloneNode(true);
        //new_select.id = type+"_select_"+(Number(id)+1);
        //new_select.name = "rule["+type+"]["+(Number(condition_id)+1)+"][keys][]";
        variable_id = 1;
        new_variable_field = document.getElementById(type+"_1_variable_1").cloneNode(true);
        new_variable_field.id = type+"_"+condition_id+"_variable_"+variable_id;
        new_variable_field.name = "rule["+type+"]["+condition_id+"][variable]["+variable_id+"][complete]";
        div1.innerHTML="";
        div1.appendChild(new_variable_field);
        //div1.appendChild(new_select);
        div1.innerHTML += "<a onclick=\"javascript:this.parentNode.innerHTML=''\">Remove</a>";
        if(condition_id>total_conditions)
          total_conditions = condition_id;
        createVariableSelectionDiv(type, id+2, condition_id, variable_id);
        attachRulesFormEventsForVariableField(type, condition_id, variable_id);
      } 
      });
}

//for Rules Engine
function createVariableSelectionDiv(type, id, condition_id, variable_id) {
  //id will be the id of new select field to be inserted
  div_id = type[0]+condition_id+"v"+variable_id;
  if($("#"+div_id).length == 0) {//div does not exist
    alert("creating new div:"+div_id);
    div1 = document.createElement('div');
    div1.id = div_id;
    last_accessed_id = id;
    new_select = document.getElementById(type+"_select_1").cloneNode(true);
    new_select.id = type+"_select_"+(id);
    new_select.name = "rule["+type+"]["+condition_id+"][variable]["+variable_id+"][keys][]";
    div1.innerHTML = "";
    div1.appendChild(new_select);
    div1.innerHTML += "<a onClick=\"javascript:this.parentNode.style.display='none';fillVariableField('"+type+"',"+condition_id+", "+variable_id+");\"><b>Done</b></a>";
    div1.style.display = "none";
    document.getElementById(type[0]+condition_id).appendChild(div1);

//    str = "<select name='rule["+type+"]["+condition_id+"][variable]["+variable_id+"][keys][]' class='rules' id='"+type+"_select_"+id+"'>"
//    str += "<option
    
    //div.innerHTML = str;
  }
}

//type is either condition or precondition
function attachRulesFormEventsForVariableField(type, condition_id, variable_id) {
  //alert('#'+type+'_'+condition_id+'_variable_'+variable_id);
  $("#"+type+"_"+condition_id+"_variable_"+variable_id).click( function(event) {
      //display the div
      //alert("hi");
      //alert("427 c"+condition_id+"v"+variable_id);
      document.getElementById("c"+condition_id+"v"+variable_id).style.display = "block";
      });
}

//for rules engine
last_accessed_id = 1;//id of last select field added
function fillVariableField(type, condition_id, variable_id) {
  children = $(("#"+type[0])+condition_id+"v"+variable_id+" select")
  str = children[0].value;
  for(var i=1; i<children.length; i++)
    str += "."+children[i].value;
  $("#"+type+"_"+condition_id+"_variable_"+variable_id).attr("value", str);
  parent_div = $("#"+type+"_"+condition_id+"_variable_"+variable_id).parent();
  
  last_accessed_id = children[children.length-1].id;//id of the last children
  //alert("445:"+last_accessed_id);
  id = Number(last_accessed_id.substring(last_accessed_id.indexOf("_select_")+"_select_".length));//this extracts out the id number at the end
  prev_field = document.getElementById(type+"_select_"+(id-1));
  if(prev_field == null)//this happens for first select of every extra condition
    prev_field = document.getElementById("select_0");
  //alert("next id to be added:"+(id+1));
  
  //type, id, prev_field, condition_id, variable_id

  $.ajax({
  url: "/rules/get?for="+document.getElementById(type+"_select_"+id).value+
      "&type="+type+
      "&id="+(Number(id)+1)+"&prev_field="+prev_field.value+
      "&condition_id="+condition_id+/*name of div boxes are c1v1, c2v1 ... where the firstnumber refers to condition_id and second to variable number local to that condition*/
      "&variable_id="+variable_id+
      "&return_only_models=false"
  ,success: function(data) {
      alert("cleaning up from"+id);
      //alert("11#"+type+"_"+condition_id+"_variable_"+(Number(variable_id)+1));
      cleanUpFields(type,id);
      $("#"+type+"_"+condition_id+"_variable_"+(Number(variable_id)+1)).remove();
      $("#"+type[0]+condition_id+"v"+(Number(variable_id)+1)).remove();
      $("#"+type+"_"+condition_id+"_variable_"+variable_id).after(data);
      if(data.indexOf("<select") != -1)
        attachRulesFormEvents(type,Number(id)+1);
      if(data.indexOf("selectmore_") != -1)
        attachRulesFormEventsForSelectMoreField(type, Number(id)+3, condition_id);
      if(data.indexOf("_variable_") != -1) {
        createVariableSelectionDiv(type, id+2, condition_id, Number(variable_id)+1);
        attachRulesFormEventsForVariableField(type, condition_id, Number(variable_id)+1);
      }
      //alert(data);
      return true;
    }
    });

}


total_cols = 0;
MAX_COLS = 20;
function attachCustomTableEvents(){
  $("#reporting_form #customtable .checkbox").click(function() {
      var type = $(this);
//      selected_field = $("#"+this.id + "_precedence_"); //#reporting_form #customtable @"+type.attr("name")+"[precedence]");
      selected_field = window.document.getElementById(this.id.replace("fields","precedence"));
      if(selected_field == null)
        return;
      if(total_cols >= MAX_COLS)
        return;
      //alert(selected_field.style.display);
      if(selected_field.style.display == "none") {
        selected_field.style.display = "";
        selected_field.selectedIndex = total_cols;
        total_cols++;
      }
      else {
        selected_field.style.display = "none";
        total_cols--;
      }

      //alert(selected_field.attr("id"));
      //selected_field.toggle();


//      window.document.getElementByName(type.name+"_precedence").innerText("Hello")

      });
}

function confirm_for(things) {
  /* given a hash of ids and values, this function asks a confirmation to proceed if the values of the elements
   * are not the same as the provided values
   */
  errors = [];
  for (thing in things) {
    if (($('#'+thing).val() != (things[thing] + "")) && $('#' + thing).val() != null) {
      errors.push(thing);
    }
  }
  if (errors.length > 0) {
    return confirm(errors.join(",") + " are not the standard value. Proceed?");
  } else {
    return true;
  }
}


$(document).ready(function(){
	create_remotes();
	$('form').highlight();
	//Handling targets form
	$("select#target_attached_to").change(function(){
		$.ajax({
			url: "/targets/all/"+$(this).val()+".json",
			success: function(data){
			    $("select#target_attached_id option").remove();
			    $.each(data, function(i, obj){
				    $("select#target_attached_id").append($("<option></option>").attr("value",obj["id"]).text(obj["name"]));
				});
			},
			dataType: "json"
		    });
	    });
	//Handling tabs
	if($("div.tab_container").length>0){
	    $("div.tab_container ul.tabs li:first").addClass("active");
	    $("div.tab_container ul.tabs li").each(function(idx, li){
		    $("div.tab_container div.tab").hide();
		    $(li).click(function(){
			    showThis($(this), idx);
			});
		});
	    li = $("div.tab_container ul.tabs li"+window.location.hash);
	    if(window.location.hash.length>0 && li.length>0){
		idx = li.index();
		showThis(li, idx);
	    }else{
		$("div.tab_container div.tab:first").show();
	    }
	    $("div.tab_container").append("<img src='/images/spinner.gif' id='spinner' style='display: none;'>");
	}
	//Handling reports
	if($("table.report").length>0 && !$("table.report").hasClass("nojs")){
	    showTableTrs();
	    var table = $("table.report");
	    table.before("<a class='expand_all'>Expand all</a>");
	    if(table.find("tr.branch td")){
		if(table.find("tr.branch").attr("id"))
		    name=table.find("tr.branch").attr("id");
		else
		    name='center';
		table.find("tr.branch td").append("<a id='"+name+"' class='expand'>Expand "+name+"s</a>");
	    }
	    if(table.find("tr.center td")){
		if(table.find("tr.center").attr("id"))
		    name=table.find("tr.center").attr("id");
		else
		    name='group';
		table.find("tr.center td").append("<a id='"+name+"' class='expand'>Expand "+name+"s</a>");
	    }
	    if(table.find("tr.date").length>0)
	       table.find("tr.group td").append("<a id='date' class='expand'>Expand dates</a>");
	    if(table.find("tr.manager").length>0)
	       table.find("tr.manager td").append("<a id='managed' class='expand'>Expand centers</a>");
	    if($("table.report tr.loan").length>0)
		$("table.report tr.group td").append("<a id='loan' class='expand'>Expand loans</a>");
	    if($("table.report tr.client").length>0)
		$("table.report tr.group td").append("<a id='client' class='expand'>Expand clients</a>");
	    $("a.expand_all").click(function(){
		    if($(this).text().indexOf("Expand")>=0){
			$("table.report tr").show();
			$(this).text($(this).text().replace('Expand', 'Collapse'));
		    }else{
			$(this).text($(this).text().replace('Collapse', 'Expand'));
			showTableTrs();
		    }
		    setToggleText();
		});
	    $("a.collapse_all").click(function(){
		    $(this).text($(this).text().replace('Collapse', 'Expand'));
		    $(this).removeClass("collapse_all").addClass("expand_all");
		    showTableTrs();
		    setToggleText();
		});
	    $("table.report tr td a").click(function(){
		    action=$(this).attr("class");
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
		id=$("#client_center_id option:selected").val() || $("#client_center_id").val();
		$.ajax({
			type: "get",
			url: "/client_groups/new?center_id="+id,
			success: function(data){
			    $("#new_client_group_form").append(data);
			    $("#new_client_group_form").submit(function(){
				    $.ajax({
					    type: "POST",
					    dataType: "json",
					    url: "/client_groups",
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
						alert("Cannot be created");
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

  if($("#client_date_of_birth_day, #client_date_of_birth_month, #client_date_of_birth_year")){
    $('#client_date_of_birth_year').parent().append('&nbsp;&nbsp;OR &nbsp;&nbsp;<span class="greytext">Enter the age in Years: </span><input size="2" id="age_year_field" type="text"></input>&nbsp;');
    $('#client_date_of_birth_month').parent().append('<span class="greytext"> Months: </span><input size="1" id="age_month_field" type="text"></input>&nbsp;');
    $('#client_date_of_birth_day').parent().append('<span class="greytext"> and Days: </span><input size="1" id="age_day_field" type="text"></input>&nbsp;');
    $('#client_date_of_birth_day').parent().append('&nbsp;&nbsp;<button id="calculateDOB">Calculate</button>');

    $('#calculateDOB').click(function(){
      dob = dateFromAge(parseInt($('#age_year_field').val()), parseInt($('#age_month_field').val()), parseInt($('#age_day_field').val()));
      $('#client_date_of_birth_year').val(dob[0]);
      $('#client_date_of_birth_month').val(dob[1]);
      $('#client_date_of_birth_day').val(dob[2]);
      return false;
    })
  }

  if($('.notice')){
    $('.notice').prepend('<div style="margin-top: 0; float:right"><a href="#" class="closeNotice" class = "closeNotice">[X]</a></div>');
  }

  $('.closeNotice').click(function(){
     $('.closeNotice').addClass('notice');
     $('.notice').remove();
  });
  $("#comments_form").submit(function(){
	  form = $("#comments_form");
	  $.ajax({
		  type: "POST",
		  url: form.attr("action"),
		  data: form.serialize(),
		  success: function(data){
		      $("table.comments").html(data);
		      $("table.comments tr:last").hide().prev().hide();
		      $("textarea#comment_text").val("");
		      $("table.comments tr:last").fadeIn("slow").prev().fadeIn("slow");
		  },
		  error: function(data){
		      alert("sorry could not add that");
		  }
	      });
	  return false;
      });
  $("#bookmark_form input:checkbox").click(function(){
	  if($(this).attr("value")==="all" && $(this).attr("checked")===true){
	      $("#bookmark_form input:checkbox").each(function(){
		      $(this).attr("checked", "true");		      
		  });
	      $("#bookmark_form input[value='none']").attr("checked", "");
	  }
	  if($(this).attr("value")==="none" && $(this).attr("checked")===true){
	      $("#bookmark_form input:checkbox").each(function(){
		      $(this).attr("checked", "");		      
		  });
	      $("#bookmark_form input[value='none']").attr("checked", "true");
	  }

      });
  $("#client_active").change(function(){
	  $("#inactive_options").toggle();
      });
  attachReportingFormEvents("formdiv_1");
  attachRulesFormEvents("condition", 0);
  attachRulesFormEvents("condition", 1);
  attachRulesFormEvents("precondition", 0);
  attachRulesFormEvents("precondition", 1);
  attachRulesFormEventsForVariableField("condition", 1/*condition_id*/, 1/*variable_id*/)
  $("a.enlarge_image").click(function(a){
	  link=$(a.currentTarget);
	  addFloater(link);
	  return(false);
      });  

//      $(".datepicker").datepicker();
});

