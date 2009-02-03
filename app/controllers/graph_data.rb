class GraphData < Application

  def loan(id)
    @loan = Loan.get(id)
    t = @loan.total_to_be_received

      
    # end time is the last of: "fully repaid", "scheduled to be repaid", "written off"
    #fully_repaid_on = @loan.history(:order => [:for_date], :conditions => ['status = ?', :repaid]).for_date
    # for now just today :-)

    @principal_scheduled_outstanding, @principal_actual_outstanding, @total_scheduled_outstanding, @total_actual_outstanding = [], [], [], []
    h = @loan.history(:order => [:for_date], :conditions => ['for_date > ? AND for_date < ?', @loan.approved_on, Date.today])
    h.each do |r|
      @principal_scheduled_outstanding << t - r.total_scheduled_principal
      @principal_actual_outstanding << t - r.total_received_principal
      @total_scheduled_outstanding << t - r.total_scheduled
      @total_actual_outstanding << t - r.total_received
    end
    step_size = t/5
    <<-JSON
{

  "elements":[
    {
      "type":      "line_dot",
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
    }, {
      "type":      "line_dot",
      "colour":    "#aa0000",
      "text":      "total_scheduled_outstanding",
      "font-size": 10,
      "width":     1,
      "dot-size":  1,
      "halo-size": 0,
      "values" :   [#{@total_scheduled_outstanding.join(',')}]
    }, {
      "type":      "line_dot",
      "colour":    "#00bb00",
      "text":      "total_actual_outstanding",
      "font-size": 10,
      "width":     1,
      "dot-size":  1,
      "halo-size": 0,
      "values" :   [#{@total_actual_outstanding.join(',')}]
    }
  ],

  "x_axis":{
    "steps": #{10},
    "colour":       "#003d4a",
    "grid-colour":  "#bc6624"
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
{
  "title":{
    "text":"Area Chart",
    "style":"{font-size: 30px;}"
  },

  "y_legend":{
    "text":"OFC",
    "style":"{font-size: 12px; color:#736AFF;}"
  },

  "elements":[
    {
      "type":      "area_hollow",
      "colour":    "#CC3399",
      "fill":      "#343399",
      "fill-alpha": 0.8,
      "text":      "Page views",
      "width":     3,
      "font-size": 10,
      "dot-size":  7,
      "values" :   [2.1,2.2]
    }
  ],

  "y_axis":{
    "stroke":       4,
    "tick-length":  10,
    "colour":       "#00ff00",
    "grid-colour":  "#d0d0d0",
    "offset":       true,
    "min":          2,
    "max":          3,
    "visible":      true,
    "steps":        0.1
  }

}

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
