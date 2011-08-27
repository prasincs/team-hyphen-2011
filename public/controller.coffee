$ ->
  UI.installHandlers()
  UI.container = $("#map")
  UI.addPlot {}, $("#interactive-plot")
  UI.draw()