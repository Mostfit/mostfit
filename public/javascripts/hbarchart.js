function init_barchart(data) {
  $('#hbarchart').html('');
  var barChart = new $jit.BarChart({
    //id of the visualization container
    injectInto: 'hbarchart',
    //whether to add animations
    animate: false,
    //horizontal or vertical barcharts
    orientation: 'horizontal',
    //bars separation
    barsOffset: 0.5,
    //visualization offset
    Margin: {
      top: 5,
      bottom: 5
    },
    //labels offset position
    labelOffset:0,
    //bars style
    type:'stacked',
    //whether to show the aggregation of the values
    showAggregates:false,
    //whether to show the labels for the bars
    showLabels:false,
    //label styles
    Label: {
      type: labelType, //Native or HTML
      size: 13,
      family: 'Arial',
      color: 'black'
    },
    //tooltip options
    Tips: {
      enable: true,
      onShow: function(tip, elem) {
	tip.innerHTML = "<b>" + elem.name + "</b>: " + elem.value;
      }
    }
      });
  //load JSON data.
  barChart.loadJSON(data);
}