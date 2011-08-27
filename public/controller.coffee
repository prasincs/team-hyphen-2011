$ ->
  UI.installHandlers()
  UI.container = $("#map")
  UI.addPlot new GameManager({}), $("#interactive-plot")
  UI.draw()