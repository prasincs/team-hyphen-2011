now = window.now

class Plot
  
  constructor : (@manager, @front, @mid, @back) ->
    @fp  = @front.getContext '2d'
    @mp  = @mid.getContext '2d'
    @bp  = @back.getContext '2d'
    @pen = @mp
    @resize()
    
  resize : ->
    @size  = @front.height
    @scale = @size / 10.0
  
  drawTiles : ->
    @bp.fillStyle = '#ddd'
    @bp.fillRect 0, 0, @size, @size
    
    @bp.fillStyle = '#eee'
    for x in [0..10]
      for y in [x%2..10] by 2
        @bp.fillRect x*@scale, y*@scale, @scale, @scale

  drawEntities : ->
    @pen = @mp
    @pen.clearRect 0, 0, @size, @size
    for x in [0..9]
      for y in [0..9]
        if e = @manager.getEntityAt(x, y)
          @[e.constructor.name.toLowerCase()](e)
    for laser in @manager.board.lasers
      @laser laser
        
  laser : (e) ->
    @pen.beginPath()
    @pen.strokeStyle = e.color
    for segment in e.segments
      [sx, sy] = segment.start.position
      
      if segment.end
        [ex, ey] = segment.end.position
      else
        switch segment.direction
          when Constants.LaserDirection.N
            [ex, ey] = [segment.start.position[0], 0]
          when Constants.LaserDirection.S
            [ex, ey] = [segment.start.position[0], 9]
          when Constants.LaserDirection.W
            [ex, ey] = [0, segment.start.position[1]]
          when Constants.LaserDirection.E
            [ex, ey] = [9, segment.start.position[1]]


      @pen.moveTo((sx+0.5)*@scale, (sy+0.5)*@scale)
      @pen.lineTo((ex+0.5)*@scale, (ey+0.5)*@scale)
    @pen.closePath()
    @pen.stroke()
    

  block : (e) ->
    [x,y] = e.position
    @pen.fillStyle = "#000000"
    @pen.fillRect x*@scale + 4, y*@scale + 4, @scale - 8, @scale - 8
    
  mirror : (e) ->
    [x, y] = e.position
    
    @pen.strokeStyle = e.color || "#000000"
    @pen.beginPath()
    if e.orientation % 2 == 1 # NW
      @pen.moveTo(x*@scale + 4, y*@scale + 4)
      @pen.lineTo((x+1)*@scale - 4, (y+1)*@scale - 4)
    else
      @pen.moveTo((x+1)*@scale - 4, y*@scale + 4)
      @pen.lineTo(x*@scale + 4, (y+1)*@scale - 4)
    @pen.closePath()
    @pen.stroke()
  
  prism : (e) ->
    [x,y] = e.position
    
    @pen.save()
    @pen.translate((x+0.5) * @scale, (y+0.5) * @scale)
    @pen.rotate(Math.PI/2 * (e.orientation-1))
    @pen.fillStyle = "#000000"
    @pen.fillRect(4-@scale/2, -@scale/2, @scale-8, 8)
    @pen.fillRect(-4, -@scale/2, 4, @scale)
    @pen.restore()
  
  filter : (e) -> @mirror(e)
    
  coordsToSquare : (e) ->
    offset = $(@front).offset()
    
    [Math.floor((e.pageX - offset.left)/@scale),
     Math.floor((e.pageY - offset.top)/@scale)]

  clearLast : () ->
    if @lastMouseMove
      @fp.clearRect @lastMouseMove[0]*@scale, @lastMouseMove[1]*@scale, @scale, @scale
    

  hoverHandler : (e) ->
    @clearLast()

    return if UI.zoomLevel < 0.5

    @lastMouseMove = [x,y] = @coordsToSquare e
        
    @fp.strokeStyle = '#00ff00' # ugly color for debugging
    @fp.strokeRect x*@scale+2, y*@scale+2, @scale-4, @scale-4

    # display tool
    if !@manager.getEntityAt(x, y) and UI.tool
      @pen = @fp
      @[UI.tool.toLowerCase()](new (window[UI.tool])([x,y], 1, true))
    
  clickHandler : (e) ->
    return if UI.zoomLevel < 0.5
    
    [x, y] = @coordsToSquare e
    
    if entity = @manager.getEntityAt(x, y)
      if e.which == 3 # right click
        @manager.removeEntityAt(x, y)
        now.entityRemoved x, y
      else
        @manager.rotateEntityClockwise(x, y)
        now.entityRotated x, y
    else if UI.tool
      e = new (window[UI.tool])([x,y], 1, true)
      @manager.addEntity e
      now.entityAdded e
      UI.tool = false
      $("#palate li").removeClass("selected")
    else
        return
      
    @drawEntities()
    UI.updateRemainingEntities()
    @clearLast()
    
UI =
  zoomLevel : 1 # between 0 and 1 with 1 being max zoom level and 0.25 being 4x further away
  plots     : []
  tool      : false
  dims      : [0, 0]
  localPlot : false
  localDiv  : false
  sprintTime: false
  nav       : false
  
  updateRemainingEntities : ->
    if @localDiv
      for e in $("#palate li")
        e = $(e)
        name = Constants.EntityType[e.data("tool").toUpperCase()]
        e.find("span").text(@localPlot.manager.remainingEntities(name))
    
  draw : ->
    for plot in @plots when plot
      plot.drawTiles()
      plot.drawEntities()
  
  updateSprintStatus : =>
    return unless typeof @sprintTime == 'number'
    if @sprintTime > 0
      $("#sprintTimer").text(Math.round((@sprintTime - Date.now())/1000))
      $("#sprintText").text("left in sprint")
    else
      $("#sprintTimer").text(Math.round((@sprintTime + Date.now())/-1000))
      $("#sprintText").text("until next sprint")

  showStartDialog : -> $("#start-panel").show()
  hideStartDialog : -> $("#start-panel").hide()

  installHandlers : ->
    
    setInterval @updateSprintStatus, 1000
      
    $(document).bind 'contextmenu', -> false
    
    @nav = $.infinitedrag("#map", {}, {
      width: 1000,
      height: 1000,
      range_col: [-5, 5] # UPDATE ME AS APPROPRAITE
      range_row: [-5, 5]
      oncreate: ->
    })
    
    $("#difficulty-menu a").click ->
      UI.hideStartDialog()
      now.requestPlot($(this).data("difficulty")) # now loading....
      false

    $(document).mousewheel (e, delta) =>

      prev = @zoomLevel
      if delta > 0
        @zoomLevel *= 1.15
      else
        @zoomLevel /= 1.15
        
      @zoomLevel = Math.max(0.1, Math.min(1, @zoomLevel)) 
      if @zoomLevel < 0.5
        $("header").fadeOut()
      else
        $("header").fadeIn()
      
      # < 1 if zoomed in
      d = @nav.draggable()                  # pretend going from 1 to 0.75
      o = d.offset()                        # -100, -100
      centerX = e.pageX         # 1000
      centerY = e.pageY
      oldX = (centerX - o.left) / prev      # 1100
      oldY = (centerY - o.top)  / prev      # 1100
      
      x = oldX*@zoomLevel + o.left
      y = oldY*@zoomLevel + o.top
      o.left += centerX - x
      o.top  += centerY - y
      
      d.offset(o)
        
      $("canvas").attr width: 500*@zoomLevel, height: 500*@zoomLevel
      for plot in @plots when plot
        plot.resize()
        d = 500 * @zoomLevel
        $(plot.front).parent().css left: "#{Math.round(d*plot.manager.gridX)}px", top: "#{Math.round(d*plot.manager.gridY)}px"

      @draw()
      
    $("#give-up").click => @showStartDialog()
      
    $("#palate li").click ->
      UI.tool = $(this).data("tool")
      $("#palate li").removeClass("selected")
      $(this).addClass("selected")
  
  scrollTo : ($e) ->    
    offset = $e.offset()
    
    centerX = $("body").width()  / 2
    centerY = $("body").height() / 2

    idealX = centerX - $e.width()/2
    idealY = centerY - $e.height()/2
    
    dx = offset.left - idealX
    dy = offset.top  - idealY
    
    dragOff = UI.nav.draggable().offset()
    dragOff.left -= dx
    dragOff.top  -= dy
    UI.nav.draggable().offset(dragOff)
  
  addPlot : (manager, mine = false) ->
    $div = $("<div/>").addClass("plot").appendTo($("#map"))
    for cls in ['bg', 'mg', 'fg']
      $div.append $("<canvas/>").attr(width: 500, height: 500).addClass("#{cls}")
    
    fg = $div.find('.fg')[0]
    mg = $div.find('.mg')[0]
    bg = $div.find('.bg')[0]
    
    p = new Plot(manager, fg, mg, bg)
    
    if mine
      @localDiv.unbind().removeClass("local") if @localDiv
      @localDiv = $div.addClass("local")
      @localPlot = p
      $div.mousemove (e) -> p.hoverHandler(e) or true
      $div.mouseup   (e) -> p.clickHandler(e) or true
      $div.mouseout  (e) -> p.clearLast()     or true
      @updateRemainingEntities()
    
    if old = @plots[manager.id || 1]
      $(old.front).parent().remove()
    
    @plots[manager.id || 1] = p
    
    p.drawTiles()
    p.drawEntities()
    
    @dims = [Math.max(@dims[0], 1+manager.gridX),
             Math.max(@dims[1], 1+manager.gridY)]
                      
    $div.css left: "#{p.size*manager.gridX}px", top: "#{p.size*manager.gridY}px"
    @scrollTo(@localDiv) if mine
