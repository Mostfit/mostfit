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

$(document).ready(function(){
	if($("div.log_box").length>0){
	    setInterval(function(){
		    spitLogs();
		}, 2000);
	}
    });