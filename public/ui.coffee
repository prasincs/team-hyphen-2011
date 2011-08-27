class Plot
  
  constructor : (@puzzle, @front, @back) ->
    @fp = @front.getContext '2d'
    @bp = @back.getContext '2d'
    @size  = @front.height
    @scale = @size / 10.0
  
  drawTiles : ->
    @bp.fillStyle = '#999999'
    @bp.fillRect 0, 0, @size, @size
    
    @bp.fillStyle = '#cccccc'
    for x in [0..10]
      for y in [x%2..10] by 2
        @bp.fillRect x*@scale, y*@scale, @scale, @scale

  #drawStatic : ->
    
  mouseMoveHandler : (e) =>
    offset = $(@front).offset()
    
    if @lastMouseMove
      @fp.clearRect @lastMouseMove[0]*@scale, @lastMouseMove[1]*@scale, @scale, @scale
    
    x = Math.floor((e.pageX - offset.left)/@scale)
    y = Math.floor((e.pageY - offset.top)/@scale)
    @lastMouseMove = [x,y]
        
    @fp.fillStyle = '#00ff00' # ugly color for debugging
    @fp.fillRect x*@scale, y*@scale, @scale, @scale


UI =
  zoomLevel : 1 # between 0 and 1 with 1 being max zoom level and 0.25 being 4x further away
  center    : [0, 0]
  plots     : []
  container : false
  
  showControls : -> @zoomLevel >= 0.75
  
  drawControls : ->
    if @showControls()
      false
      
  draw : ->
    for plot in @plots
      plot.drawTiles()

  addPlot : (puzzle, $div) ->
    p = new Plot(puzzle, $div.find('.fg')[0], $div.find('.bg')[0])
    $div.mousemove p.mouseMoveHandler
    @plots.push p