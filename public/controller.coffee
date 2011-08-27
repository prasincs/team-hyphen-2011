$ ->
  UI.installHandlers()
  UI.container = $("#map")
  UI.addPlot new GameManager({getMaxForType:(x)->100000}), $("#interactive-plot"), true
  UI.draw()