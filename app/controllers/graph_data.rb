class GraphData < Application

  def index
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
  "title":{"text":"Income"},
  "bg_colour":"#FFFFFF"
}
    JSON
  end
  
end
