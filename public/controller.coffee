$ ->
  UI.installHandlers()
  UI.container = $("#map")
  
  UI.addPlot new GameManager(new Puzzle(), 0, 0), true
  UI.addPlot new GameManager(new Puzzle(), 1, 0)
  UI.addPlot new GameManager(new Puzzle(), 0, 1)
  UI.addPlot new GameManager(new Puzzle(), 0, 2)
  UI.addPlot new GameManager(new Puzzle(), 3, 3)
  
  UI.draw()
  
  
  now = window.now ?= {}

  now.startPlot = (x, y, puzzle, local = false) ->
    UI.addPlot new GameManager(puzzle, x, y), local
    
  now.addEntity = (x, y, e) ->
    UI.plots[x][y].addEntity(e)
    
  now.removeEntity = (x, y) ->
    UI.plots[x][y].removeEntityAt(x,y)
