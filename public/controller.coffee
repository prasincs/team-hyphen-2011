$ ->
  UI.installHandlers()
  
  UI.draw()
  
  reconstitute = (blank, data) -> data.__proto__ = blank
  
  notMyPlot = (plotId) ->
    plot = UI.plots[plotId]
    plot
  
  now = window.now ?= {}

  now.startPlot = (id, coords, puzzle, clientId) ->
    x = coords[0]
    y = coords[1]
    reconstitute new Puzzle(1), puzzle
    manager = new GameManager(id, puzzle, x, y)
    manager.deserializePuzzle()

    UI.addPlot manager, now.core.clientId == clientId
    now.requestNeighborPlots id
    UI.draw()

  now.drawPlot = (id, [x,y], puzzle, clientId) ->
    if clientId != now.core.clientId
      reconstitute new Puzzle(1), puzzle
      manager = new GameManager(id, puzzle, x, y)
      manager.deserializePuzzle()
      UI.addPlot manager

  
  now.addEntity = (plotId, e) ->
    switch e.type
      when Constants.EntityType.MIRROR
        notMyPlot(plotId)?.mirror(e)
      when Constants.EntityType.PRISM
        notMyPlot(plotId)?.prism(e)
      when Constants.EntityType.FILTER
        notMyPlot(plotId)?.filter(e)
  
  now.removeEntity = (plot, x, y) ->
    notMyPlot(plot)?.removeEntityAt(x,y)
    
  now.rotateEntity = (plot, x, y) ->
    notMyPlot(plot)?.rotateEntityClockwise(x, y)
    
  now.updateScores = (spintScores, highscores) ->
    unimplemented
  
  now.puzzleCompleted = ->
    UI.showStartDialog()
    
  now.startSprint = (timeLeft) ->
    UI.sprintTime = Date.now() + timeLeft
    UI.plots = []
    $(".plot").remove()
  
  now.endSprint = (timeLeft) ->
    UI.sprintTime = - timeLeft - Date.now()

