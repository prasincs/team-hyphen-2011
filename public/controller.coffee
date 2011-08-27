$ ->
  UI.installHandlers()
  UI.container = $("#map")
  
  UI.addPlot new GameManager(new Puzzle(), 0, 0), $("#interactive-plot"), true
  UI.addPlot new GameManager(new Puzzle(), 1, 0)
  UI.addPlot new GameManager(new Puzzle(), 0, 1)
  UI.addPlot new GameManager(new Puzzle(), 0, 2)
  UI.addPlot new GameManager(new Puzzle(), 0, 3)
  
  UI.draw()
  
  now = window.now
  
  # now.updatePlot = (x, y, spec) ->
  #   UI.plots[x][y] = 