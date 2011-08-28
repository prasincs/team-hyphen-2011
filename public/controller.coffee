$ ->
  UI.installHandlers()
  
  UI.draw()
  
  reconstitute = (blank, data) -> data.__proto__ = blank
  
  notMyPlot = (plotId) ->
    console.log plotId , "<-- plotId"
    console.log UI.plots
    plot = UI.plots[plotId]
    plot
  
  now = window.now ?= {}

  now.startPlot = (id, [x, y], puzzle, clientId) ->
    reconstitute new Puzzle(1), puzzle
    UI.addPlot new GameManager(id, puzzle, x, y), now.core.clientId == clientId
    now.requestNeighborPlots id

  now.drawPlot = (id, [x,y], puzzle, clientId) ->
    reconstitute new Puzzle(1), puzzle
    if clientId != now.core.clientId
      UI.addPlot new GameManager(id, puzzle, x, y)

  
  now.addEntity = (plotId, e) ->
    console.log plotId, UI.localPlot.manager.id
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

