// Common JavaScript code across your application goes here.
var lineNos=0;
function addFloater(link, form){
    if($(".floatingBox").length>0 && link){
	if(window.document.width > link.offset().left + link.width() + form.width()){
	    var left = link.offset().left + link.width();
	}else{
	    var left =  link.width() + link.offset().left - form.width();
	}
	if((window.document.height > form.offset().top + form.height()) && !$(".floatingBox").hasClass("shiftUp")){
	    var top = link.offset().top + link.height();
	}else{
	    var top = link.offset().top - form.height();
	}
	$(form).offset({top: top, left: left});
    }

    if($(".floater").length>0){
	$(link).after("<div class='floater'><img height='400' src="+link.attr('href')+"/><span class='close_button'>X</span></div>");
	$(".close_button").live('click', function(button){
				    $("div.floater").remove();
				});
    }
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
				       if(!$(this).hasClass("link")){
					   if($(this).parent().parent().next().css("display")!="none"){
					       $(this).text($(this).text().replace('Expand', 'Collapse'));
					       $(this).addClass('collapse');
					       $(this).removeClass('expand');
					   }else{
					       $(this).text($(this).text().replace('Collapse', 'Expand'));
					       $(this).addClass('expand');
					       $(this).removeClass('collapse');
					   }
				       }
				   });
}
function showThis(li, idx){
    $("div.tab_container div.tab").hide();
    $("div.tab_container ul.tabs li.active").removeClass("active");
    $(li).addClass("active");
    tab = $($("div.tab_container div.tab")[idx]).show();
    remote = $(tab).find("input:hidden");
    if(typeof centerMap !="undefined")
	centerMap();
    if(remote.length>0 && remote.attr("name")=="_load_remote"){
	$.ajax({
		   url: remote.val(),
		   success: function(data){
		       $($("div.tab_container div.tab")[idx]).html(data);
		       if(typeof map_initialize != 'undefined'){
			   map_initialize();
			   $("#map_canvas").css("height", $(window).height()*4/5);
		       }
		   },
		   beforeSend: function(){
		       $('#spinner').show();
		   },
		   error: function(xhr, text, errorThrown){
		       txt = "<div class='error'>"+xhr.responseText+"</div>";
		       $($("div.tab_container div.tab")[idx]).html(txt);
		   },
		   complete: function(){
		       $('#spinner').hide();
		   }
	       });
	remote.remove();
    }
    if(window.location.hash.length>0 && window.location.hash.indexOf($(li).attr("id"))>0 && window.location.hash!=$(li).attr("id")){
	window.location.hash=window.location.hash;
    }else{
	window.location.hash=$(li).attr("id");
    }
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
function attachFormRemote(){
    $("form._remote_").live('submit', function(f){
				form=$(f.currentTarget);
				$(form).find("input[type='submit']").attr("disabled", true);
				$(form).after("<img id='spinner' src='/images/spinner.gif' />");
				$(".floatingBox").remove();
				$.ajax({
					   type: form.attr("method"),
					   url: form.attr("action"),
					   data: form.serialize(),
					   success: function(data, status, xmlObj){
					       if(data.redirect){
						   window.location.href = data.redirect;
					       }else if(form.find("input[name='_target_']").length>0){
						   id=form.find("input[name='_target_']").attr("value");
						   if($("#"+id).length>0){
						       $("#" + id).html(data);
						   }
						   else if($("#append_"+id).length>0){
						       $(data).appendTo($("#append_"+id));
						   }
					       }else if(form.find("table").length>0){
						   form.find("table").html(data);
					       }else if(form.find("div").length>0){
						   form.find("div").html(data);
					       }
					       if($(".floatingBox").length>0)
						   addFloater($(form), $($(".floatingBox")[0]));
					       $(form).find("input[type='submit']").attr("disabled", "");
					       $("#spinner").remove();
					   },
					   error: function(xhr, text, errorThrown){
					       if(xhr.status=="302"){
						   window.location.href = text;
					       }else{
						   $("div.error").remove();
						   txt = "<div class='error'>"+xhr.responseText+"</div>";
						   form.before(txt);
						   $(form).find("input[type='submit']").attr("disabled", "");
					       }
					       $("#spinner").remove();
					   }
				       });
				return(false);
			    });
}
function create_remotes(){
    $("a._remote_").live('click', function(){
			     href=$(this).attr("href");
			     method="GET";
			     if($(this).hasClass("self")){
				 href=href+(href.indexOf("?")>-1 ? "&" : "?")+$(this).parent().serialize();
				 method="POST";
			     }
			     a=$(this);
			     a.after("<img id='spinner' src='/images/spinner.gif'/>");
			     $.ajax({
					type: method,
					url: href,
					success: function(data){
					    if($(a).attr("id") && $("#container_"+$(a).attr("id")).length>0){
						$("#container_"+$(a).attr("id")).html(data);
					    }else if($(a).attr("id") && $("#after_"+$(a).attr("id")).length>0){
						$("#after_"+$(a).attr("id")).after(data);
					    }else if($(a).attr("id") && $("#"+$(a).attr("id")).length>0){
						$("#"+$(a).attr("id")).html(data);
					    }else{
						$(a).after(data);
						$(a).remove();
					    }
					    floatHeaders();
					    $("#spinner").remove();
					},
					error: function(xhr, text, errorThrown){
					    txt = "<div class='error'>"+xhr.responseText+"</div>";
					    $(a).after(txt);
					    $("#spinner").remove();
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
    $('.confirm_click').each(function(idx, link){
				 $(link).unbind();
				 $(link).click(function(event) {
						   link = event.currentTarget;
						   str  = $(link).attr("title") || 'Are you sure?';
						   var answer = confirm(str);
						   return answer;
					       });
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
											      if(name!="value"){
												  for(i=types.indexOf(name)+1; i<=types.length; i++){
												      $("#reporting_form select#"+types[i]+"_"+counter).html("");
												  }
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
					 if(id+1> total_fields)
					     total_fields = id+10;//delete some more fields than id+1 since sometimes more than 1 field is returned per request(there is no harm is deleting extra fields anyways)
					 if(id == 0)
					     return;//special case to handle that
					 parent_div_id = document.getElementById(type+"_select_"+id).parentNode.id;//it is of type c1v2=> condition 1, variable 2
					 condition_id = Number(parent_div_id.substr(1,1));//now this is with assumption that condition_id is single digit (can there be more than 9 conditions ever? if that happens this code fails)
					 variable_id = Number(parent_div_id.substr(3,1));//since we have only two variables per condition, variable_id will be single digit
           for_element = $('#' + type + '_select_' + id);
					 $.ajax({
						    url: "/rules/get?for="+for_element.val()+
							"&type="+type+
							"&id="+(Number(id)+1)+"&prev_field="+for_element.attr('model')+
							"&condition_id="+condition_id+/*name of div boxes are c1v1, c2v1 ... where the firstnumber refers to condition_id and second to variable number local to that condition*/
						    "&variable_id="+variable_id+
							"&return_only_models=true"
						    ,success: function(data) {
							cleanUpFields(type,id);
							$("#"+type+"_select_"+id).after(data);
							if(data.indexOf("<select") != -1) {
							    attachRulesFormEvents(type,Number(id)+1);
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
	//alert("creating new div:"+div_id);
	div1 = document.createElement('div');
	div1.id = div_id;
	new_select = document.getElementById(type+"_select_1").cloneNode(true);
	new_select.id = type+"_select_"+(id);
	new_select.name = "rule["+type+"]["+condition_id+"][variable]["+variable_id+"][keys][]";
	if(variable_id>1) {
	    nilOption = document.createElement("option");
	    nilOption.value = "0";
	    nilOption.appendChild(document.createTextNode("0"));
	    new_select.appendChild(nilOption);
	}
	div1.innerHTML = "<b>Condition "+condition_id+" Variable "+variable_id+"</b>";
	div1.appendChild(new_select);
	div1.innerHTML += "<a onClick=\"javascript:this.parentNode.style.display='none';fillVariableField('"+type+"',"+condition_id+", "+variable_id+");\"><b>Done</b></a>";
	div1.style.display = "none";
	document.getElementById(type[0]+condition_id).appendChild(div1);
    }
}

//type is either condition or precondition
function attachRulesFormEventsForVariableField(type, condition_id, variable_id) {
    $("#"+type+"_"+condition_id+"_variable_"+variable_id).click( function(event) {
								     document.getElementById(type[0]+condition_id+"v"+variable_id).style.display = "block";
								 });
}

//for rules engine
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
    for_field = document.getElementById(type+"_select_"+id);
    for_field_value = for_field.value;
    prev_field = document.getElementById(type+"_select_"+(id-1));
    if(prev_field == null)//this happens for first select of every extra condition
	prev_field = document.getElementById("select_0");
    single_variable_mode = 0;
    if(for_field_value == "0" ) {//this handles the case when second variable has been selected to be 0(nil), in that case, we will try to return the value of two fields prior to this (since between these two there is a select field wil binaryoperator)
	for_field_value = document.getElementById(type+"_select_"+(id-2)).value;
	single_variable_mode = 1;
    }

    prev_value = $('#' + type + '_select_' + id).attr('model')

    $.ajax({
	       url: "/rules/get?for="+for_field_value+
		   "&type="+type+
		   "&id="+(Number(id)+1)+"&prev_field="+prev_value+
		   "&condition_id="+condition_id+/*name of div boxes are c1v1, c2v1 ... where the firstnumber refers to condition_id and second to variable number local to that condition*/
	       "&variable_id="+variable_id+
		   "&single_variable_mode="+single_variable_mode+
		   "&return_only_models=false"
	       ,success: function(data) {
		   //alert("cleaning up from"+id);
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
		       attachRulesFormEvents(type, id+2);
		   }
		   //alert(data);
		   return true;
	       }
	   });
}


MAX_COLS = 20;
function attachCustomTableEvents(){
    $("#reporting_form #customtable .checkbox").click(function() {
							  var arr=[];
							  $("#customtable tr select").each(function(idx, select){
											       if($(select).css("display")!="none")
												   arr.push(parseInt($(select).val()));
											   });
							  var total_cols = arr.sort()[arr.length - 1];
							  var type = $(this);
							  selected_field = window.document.getElementById(this.id.replace("fields","precedence"));
							  if(selected_field == null)
							      return;
							  if(total_cols >= MAX_COLS)
							      return;
							  if(selected_field.style.display == "none") {
							      selected_field.style.display = "block";
							      selected_field.selectedIndex = total_cols;
							      total_cols++;
							  }else{
							      selected_field.style.display = "none";
							      total_cols--;
							  }
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

function fillCenters(){
    $("#branch_selector").change(function(){
				     $.ajax({
						type: "GET",
						url: "/branches/centers/"+$("#branch_selector").val(),
						success: function(data){
						    $("#center_selector").html(data);
						}
					    });
				 });
}

function fillComboBranches(){
    $("#area_selector").change(function(){
	$.ajax({
	    type: "GET",
	    url: "/areas/branches/"+$("#area_selector").val(),
	    success: function(data){
		$("#combo_branch_selector").html(data);
	    }
	});
    });
}

function fillAccounts(){
    if($("#account_selector").length > 0){
	$("#branch_selector").change(function(){
					 $.ajax({
					            type: "GET",
						    url: "/branches/accounts/"+$("#branch_selector").val(),
						    success: function(data){
							$("#account_selector").html(data);
						    }
						});
	                             });
    }
}

function fillCashAccounts(){
    if($("#cash_account_selector").length > 0){
	$("#branch_selector").change(function(){
					 $.ajax({
					            type: "GET",
						    url: "/branches/cash_accounts/"+$("#branch_selector").val(),
						    success: function(data){
							$("#cash_account_selector").html(data);
						    }
						});
	                             });
    }
}

function fillBankAccounts(){
    if($("#bank_account_selector").length > 0){
	$("#branch_selector").change(function(){
					 $.ajax({
					            type: "GET",
						    url: "/branches/bank_accounts/"+$("#branch_selector").val(),
						    success: function(data){
							$("#bank_account_selector").html(data);
						    }
						});
				     });
    }
}

function fillFundingLines(){
    $("#funder_selector").change(function(){
	                             $.ajax({
					         type: "GET",
						 url: "/funders/funding_lines/"+$("#funder_selector").val(),
						 success: function(data){
						     $("#funding_line_selector").html(data);
					         }
					     });
	                         });
}

function floatHeaders(){
    if($("table.report").length>0){
	$('.report').floatHeader({
				     fadeIn: 250,
				     fadeOut: 250,
				     forceClass: true,
				     recalculate: true,
				     markerClass: 'header'
				 });
    }
    if($("table.floating_header").length>0){
	$('table.floating_header').floatHeader({
						   fadeIn: 250,
						   fadeOut: 250,
						   forceClass: true,
						   recalculate: true,
						   markerClass: 'header'
					       });
    }
}

function portfolioCalculations(){
    $("table.portfolio input[type='checkbox']").click(function(event){
							  tr = $(event.currentTarget).parent().parent();
							  $($(tr).find("td")[4]).html($($(tr).find("td")[1]).html().trim());
							  $($(tr).find("td")[5]).html($($(tr).find("td")[2]).html().trim());
							  $($(tr).find("td")[6]).html($($(tr).find("td")[2]).html().trim());

							  if($(event.currentTarget).attr("checked")){
							      //setting branch total
							      [3, 4, 5, 6].forEach(function(td_id){
										       if(td_id == 3){
											   var td_val = 1;
										       }else{
											   var td = $($(tr).find("td")[td_id]);
											   var td_val = parseInt(td.html().replace(/\s|\,/g, ''));
										       }
										       var branch_val = parseInt($($(tr.nextAll("tr.branch_total")[0]).find("td b")[td_id]).html().replace(/\s|\,/g, '')) || 0;
										       $($($(tr.nextAll("tr.branch_total")[0]).find("td")[td_id])).html("<b>" + (branch_val + td_val) + "</b>") || 0;
										   });
							  }else{
							      //setting branch total
							      [3, 4, 5, 6].forEach(function(td_id){
										       if(td_id == 3){
											   var td_val = 1;
										       }else{
											   var td = $($(tr).find("td")[td_id]);
											   var td_val = parseInt(td.html().replace(/\s|\,/g, ''));
										       }
										       var branch_val = parseInt($($(tr.nextAll("tr.branch_total")[0]).find("td b")[td_id]).html().replace(/\s|\,/g, '')) || 0;
										       $($($(tr.nextAll("tr.branch_total")[0]).find("td")[td_id])).html("<b>" + (branch_val - td_val) + "</b>") || 0;
										   });
							      $($(tr).find("td")[4]).html("0");
							      $($(tr).find("td")[5]).html("0");
							      $($(tr).find("td")[6]).html("0");
							  }

							  //setting org total
							  var org_client_count = 0;
							  var org_count = 0;
							  var org_allocated = 0;
							  var org_current = 0;
							  $("tr.branch_total").each(function(idx, tr){
											org_client_count += parseInt($($(tr).find("td b")[3]).html().replace(/\s|\,/g, '')) || 0;
											org_count += parseInt($($(tr).find("td b")[4]).html().replace(/\s|\,/g, '')) || 0;
											org_allocated += parseInt($($(tr).find("td b")[5]).html().replace(/\s|\,/g, '')) || 0;
											org_current += parseInt($($(tr).find("td b")[6]).html().replace(/\s|\,/g, '')) || 0;
										    });
							  $($("tr.org_total:first td")[3]).html("<b>" + org_client_count + "</b>");
							  $($("tr.org_total:first td")[4]).html("<b>" + org_count + "</b>");
							  $($("tr.org_total:first td")[5]).html("<b>" + org_allocated + "</b>");
							  $($("tr.org_total:first td")[6]).html("<b>" + org_current + "</b>");
						      });
}
$(document).ready(function(){
		      create_remotes();
		      attachFormRemote();
                      fillCenters();
                      fillComboBranches();
		      fillAccounts();
		      fillFundingLines();
		      fillCashAccounts();
		      fillBankAccounts();
		    $('.chosen').chosen();
		    $('input#submit').addClass("greenButton");
		    $('button.add').addClass("greenButton");
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
										     $(".graphContainer:visible .graphs:first").toggle();
										 });
								 });
			  id = window.location.hash.split("/")[0];
			  li = $("div.tab_container ul.tabs li"+id);
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
			  //level 2
			  if(table.find("tr.branch td")){
			      if(table.find("tr.branch").attr("id"))
				  level2_name=table.find("tr.branch").attr("id");
			      else
				  level2_name='center';
			      if(table.find("tr." + level2_name).length>0)
				  table.find("tr.branch td").append("<a id='"+level2_name+"' class='expand'>Expand " + level2_name.split("_").join(" ") + "s</a>");
			      //level 3
			      if(table.find("tr." + level2_name + " td")){
				  if(table.find("tr." + level2_name).attr("id"))
				      level3_name=table.find("tr."+level2_name).attr("id");
				  else
				      level3_name='group';
				  if(table.find("tr." + level3_name).length>0)
				      table.find("tr."+ level2_name + " td").append("<a id='"+level3_name+"' class='expand'>Expand " + level3_name.split("_").join(" ") + "s</a>");
				  //level 4
				  if(table.find("tr." + level3_name + " td").length>0){
				      if(table.find("tr." + level3_name).attr("id"))
					  level4_name=table.find("tr."+level3_name).attr("id");
				      else
					  level4_name='date';
				      if(table.find("tr." + level4_name).length>0)
					  table.find("tr."+ level3_name + " td").append("<a id='" + level4_name + "' class='expand'>Expand " + level4_name.split("_").join(" ") + "s</a>");
				  }
			      }
			  }
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
								  setToggleText();
							      }else if(action === "collapse"){
								  $(this).parent().parent().nextUntil("tr."+parent_type_total).hide();
								  $(this).parent().parent().nextUntil("tr."+parent_type_total).hide();
								  setToggleText();
								  if(parent_type=="branch")
								      $(this).parent().parent().nextUntil("tr.branch_total").hide();
							      }
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
						   });
		      }

		      if($('.notice')){
			  $('.notice').prepend('<div style="margin-top: 0; float:right"><a href="#" class="closeNotice" class = "closeNotice">[X]</a></div>');
		      }

		      $('.closeNotice').click(function(){
						  $('.closeNotice').addClass('notice');
						  $('.notice').remove();
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
		      /*sample = function(select){
			  val=$("#account_branch_id").val();
			  val1=$("#account_account_type_id").val();
			  $.ajax({
				  url: "/accounts?branch_id="+val+"&account_type_id="+val1,
				      success: function(data){$("#account_parent_id").html(data);}
			      });
		      }
		      $("#account_account_type_id").live('change', sample);
		      $("#account_branch_type_id").live('change', sample);*/
		      $("#account_account_type_id").live('change', function(select){
							     val=$("#account_branch_id").val();
							     val1=$("#account_account_type_id").val();
							     $.ajax({
								     url: "/accounts?branch_id="+val+"&account_type_id="+val1,
									 success: function(data){$("#account_parent_id").html(data);}
								 });
			  });
		      $("#account_branch_id").live('change', function(select){
							     val=$("#account_branch_id").val();
							     val1=$("#account_account_type_id").val();
							     $.ajax({
								     url: "/accounts?branch_id="+val+"&account_type_id="+val1,
									 success: function(data){$("#account_parent_id").html(data);}
								 });
			  });
		      attachReportingFormEvents("formdiv_1");
		      attachRulesFormEvents("condition", 0);
		      attachRulesFormEvents("condition", 1);
		      attachRulesFormEvents("precondition", 0);
		      attachRulesFormEvents("precondition", 1);
		      attachRulesFormEventsForVariableField("condition", 1/*condition_id*/, 1/*variable_id*/);
		      attachRulesFormEventsForVariableField("precondition", 1/*condition_id*/, 1/*variable_id*/);
		      $("a.enlarge_image").click(function(a){
						     link=$(a.currentTarget);
						     addFloater(link, $(a));
						     return(false);
						 });
		      if($("#rule_book_action").length>0){
			  function showHideFees(){
			      if($("#rule_book_action").val()==="fees")
				  $("#fees_row").show();
			      else
				  $("#fees_row").hide();
			  }
			  showHideFees();
			  $("#rule_book_action").change(function(){
							    showHideFees();
							});
		      }
		      $("form._disable_button_").live('submit', function(form){
							    $(form.currentTarget).find("input[type='submit']").attr('disabled', true);
							    return(true);
							});
		      $("a._rejection_button_").click(function(a){
							  if(confirm('Do you really want to reject these loans?')){
							      form = $($(a.currentTarget).parent()[0]);
							      form.attr("action", $(a.currentTarget).attr("href"));
							      form.submit();
							      return false;
							  }else{
							      return false;
							  }
						      });

		      $("#client_active").change(function(){
						     $("#inactive_options").toggle();
						 });
		      $("a.expand_collapsed").click(function(a){
							id = $(a.currentTarget).attr("id");
							if((id && $("#element_" + id).length > 0)){
							    $("#element_" + id).toggle();
							}else{
							    $(".collapsed").toggle();
							}
							if($(a.currentTarget).css("background-image").indexOf("closed.gif")>0){
							    $(a.currentTarget).css("background-image", "url(/images/elements/open.gif)");
							}else{
							    $(a.currentTarget).css("background-image", "url(/images/elements/closed.gif)");
							}
						    });
		      if($(".graphContainer").length>0){
			  $(".graphContainer .graphs:first").toggle();
			  $(".graphContainer .listContainer ul li").click(function(liClicked){
									      li=liClicked.currentTarget;
									      container=$(li).parent().parent().parent();
									      container.find("li.selected").removeClass("selected");
									      idx=$(li).index();
									      if(window.location.hash.split("/")[0].length>0){
										  id=window.location.hash.split("/")[0];
									      }else{
										  id="#"+$(li).parent().attr("id");
									      }
									      window.location.hash=id+"/"+(idx+1);
									      $(".graphContainer:visible").siblings().attr("action", "/dashboard"+window.location.hash);
									      $(container).find(".graphs").hide();
									      $($(container).find(".graphs")[idx]).show();
									      $(li).addClass("selected");
									  });
			  if(window.location.hash.length>0){
			      container=$(".graphContainer:visible");
			      if(window.location.hash.indexOf("/")>0)
				  idx=parseInt(window.location.hash.split("/")[1])-1;
			      else
				  idx=0;
			      container.find("li.selected").removeClass("selected");
			      $($(container).find(".listContainer ul li")[idx]).addClass("selected");
			      $(container).find(".graphs").hide();
			      $($(container).find(".graphs")[idx]).show();
			  }
		      }
		      if($(".portfolio").length>0){
			  portfolioCalculations();
		      }

		      $("table#user_form select#user_role").change(function(select){
								       if($(select.currentTarget).val()==="funder"){
									   $("#user_form .staff_member").hide();
									   $("#user_form .funder").show();
									   $("#user_form #user_staff_member").val("");
								       }
								       if($(select.currentTarget).val()==="staff_member"){
									   $("#user_form .staff_member").show();
									   $("#user_form .funder").hide();
									   $("#user_form #user_funder").val("");
								       }
								       if($(select.currentTarget).val()==="accountant"){
									   $("#user_form .staff_member").hide();
									   $("#user_form .funder").hide();
									   $("#user_form #user_funder").val("");
									   $("#user_form #staff_member").val("");
								       }
								   });
		      floatHeaders();
		      if($("#tree").length>0){
			  $("#tree").treeview({
						  collapsed: false,
						  animated: "medium",
						  control:"#sidetreecontrol"
					      });
		      }
		      if($("#audit_trail_form").length>0){
			  $("#audit_trail_form select#auditable_type").change(function(){
										  $.ajax({
											     type: "GET",
											     url: "/searches/get?counter=0&model[0]=" + $(this).val(),
											     success: function(data){
												 $("#audit_col").remove();
												 $("select#auditable_type").after("<b>of</b><select id=\"audit_col\" name=\"col\">" + data + "</select>");
											     }
											 });
									      });
		      }
		      if($("table#customtable").length>0){
			  attachCustomTableEvents();
		      }
		      addFloater("");
		      if(typeof map_initialize != 'undefined')
			  map_initialize();
		      if($("#map_canvas") && (typeof loadAPI != "undefined"))
			  loadAPI();
		      $("a.closeButton").live('click', function(){
						  $(".floatingBox").remove();
					      });
		  });

