class GraphData < Application

  def loan(id)
    @loan = Loan.get(id)
    t = @loan.total_to_be_received

      
    # end time is the last of: "fully repaid", "scheduled to be repaid", "written off"
    #fully_repaid_on = @loan.history(:order => [:date], :conditions => ['status = ?', :repaid]).date
    # for now just today :-)

    @principal_scheduled_outstanding, @principal_actual_outstanding, @total_scheduled_outstanding, @total_actual_outstanding, @labels = [], [], [], [], []
    h = @loan.history(:order => [:date], :conditions => ['date > ? AND date < ?', @loan.approved_on, @loan.last_loan_history_date])
    h.each_with_index do |r, index|
#       @principal_scheduled_outstanding << t - r.total_scheduled_principal
#       @principal_actual_outstanding    << t - r.total_received_principal
      @total_scheduled_outstanding     << t - r.total_scheduled
      @total_actual_outstanding        << {
        'value'     => t - r.total_received,
        'colour'    => (r.total_received < r.total_scheduled ? '#ff0000' : '#00ff00') }.to_json
      @labels                          << ((index % 14 == 0) ? r.date.strftime("%d%b'%y") : '')
    end
    step_size = t/5
    <<-JSON
{
  "elements":[
    { /*
      "type":      "scatter",
      "colour":    "#FFB900",
      "text":      "Avg",
      "font-size": 10,
      "dot-size":  10,
      "values" :   [
                     {"x":2,  "y":100, "tip":"HELLO" },
                     {"x":6,  "y":500,  "colour":"#FF0000" },
                     {"x":5,  "y":100,  "dot-size":20},
                     {"x":4,  "y":150, "dot-size":5},
                     {"x":3,  "y":200,  "dot-size":5},
                     {"x":2,  "y":300,  "dot-size":15}
                   ]
    }, { */
/*      "type":      "line_dot",
      "colour":    "#736AFF",
      "text":      "principal_scheduled_outstanding",
      "font-size": 10,
      "width":     1,
      "dot-size":  1,
      "halo-size": 0,
      "values" :   [#{@principal_scheduled_outstanding.join(',')}]
    }, {
      "type":      "line_dot",
      "colour":    "#736A00",
      "text":      "principal_actual_outstanding",
      "font-size": 10,
      "width":     1,
      "dot-size":  1,
      "halo-size": 0,
      "values" :   [#{@principal_actual_outstanding.join(',')}]
    }, { */
      "type":      "line_dot",
      "colour":    "#aa0000",
      "text":      "total_scheduled_outstanding",
      "font-size": 10,
      "width":     3,
      "dot-size":  1,
      "halo-size": 0,
      "values" :   [#{@total_scheduled_outstanding.join(',')}]
    }, {
      "type":      "line_dot",
      "colour":    "#555555",
      "text":      "total_actual_outstanding",
      "font-size": 10,
      "width":     2,
      "dot-size":  2,
      "halo-size": 1,
      "values" :   [#{@total_actual_outstanding.join(',')}]
    }
  ],

  "x_axis":{
    "steps":        #{7},
    "colour":       "#003d4a",
    "grid-colour":  "#bc6624",
    "labels":       {"labels":#{@labels.to_json}}
  },

  "y_axis":{
    "colour":       "#003d4a",
    "grid-colour":  "#bc6624",
    "steps": #{step_size},
    "min": 0,
    "max": #{t}
  },
  "bg_colour":"#ffffff"

}
    JSON
  end

  def client
    <<-JSON
{ "elements": [ { 
"type": "bar_stack", 
"colours": [ "#C4D318", "#50284A", "#7D7B6A" ], 
"values": [ [ 2.5, 5, 2.5 ], [ 2.5, 5, 1.25, 1.25 ], [ 5, { "val": 5, "colour": "#ff0000" } ], [ 2, 2, 2, 2, { "val": 2, "colour": "#ff00ff" } ] ], 
"keys": [ 
{ "colour": "#C4D318", "text": "Kiting", "font-size": 13 }, 
{ "colour": "#50284A", "text": "Work", "font-size": 13 }, 
{ "colour": "#7D7B6A", "text": "Drinking", "font-size": 13 }, 
{ "colour": "#ff0000", "text": "XXX", "font-size": 13 }, 
{ "colour": "#ff00ff", "text": "What rhymes with purple? Nurple?", "font-size": 13 } ], 
"tip": "X label [#x_label#], Value [#val#]
Total [#total#]" } ], 
"title": { "text": "Stuff I'm thinking about, Tue Feb 03 2009", "style": "{font-size: 20px; color: #F24062; text-align: center;}" }, 
"x_axis": { "labels": { "labels": [ "Winter", "Spring", "Summer", "Autmn" ] } }, 
"y_axis": { "min": 0, "max": 14, "steps": 2 }, 
"tooltip": { "mouse": 2 } }

    JSON
end


  def center
    <<-JSON
{
  "series":
    [{
      "items":4,
      "steps":1,
      "options":{"date_label_formatter":"%b %Y","date_key_formatter":"%Y-%m","items":4,"title":"Media"},
      "json_class":"OpenFlashChartLazy::Serie",
      "title":"Media",
      "keys":[],
      "max":0,
      "values":[40000,10000,50000,40000],
      "min":0,
      "labels":["tv","internet","magazines","other"],
      "data":[["tv",40000],["internet",10000],["magazines",50000],["other",40000]]
    }],
  "elements":[{"text":"Media","type":"line","values":[40000,10000,50000,40000]}],
  "x_axis":
    {
      "colour":"#808080",
      "grid-colour":"#A0A0A0",
      "labels":{"colour":"#909090","3d":10,"labels":["tv","internet","magazines","other"]}
    },
    "y_axis":
    {
      "steps":25000,
      "max":80000,
      "colour":"#808080",
      "min":0,
      "grid-colour":"#A0A0A0"
    },
  "title":{"text":"#{params[:resource]}"},
  "bg_colour":"#ffffff"
}
    JSON
  end
  
end
