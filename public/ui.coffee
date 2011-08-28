now = window.now

ImageManager =
  cache : {}
  patternCache : {}
  get : (name) ->
    @cache[name] ||= $("<img/>").attr(src: "/images/#{name}.png")[0]
  draw  : (name, pen, x, y, w, h) ->
    pen.drawImage(@get(name), x, y, w, h)

class Plot  
  constructor : (@manager, @front, @mid, @back) ->
    @fp  = @front.getContext '2d'
    @mp  = @mid.getContext '2d'
    @bp  = @back.getContext '2d'
    @pen = @mp
    @drawQueue = []
    @resize()
    
  resize : ->
    @size  = @front.height
    @scale = @size / 10.0
  
  drawTiles : ->
    @bp.fillStyle = '#222'
    @bp.fillRect 0, 0, @size, @size
    
    @bp.fillStyle = '#111'
    for x in [0..10]
      for y in [x%2..10] by 2
        @bp.fillRect x*@scale, y*@scale, @scale, @scale

  drawEntities : ->
    @pen = @mp
    @pen.clearRect 0, 0, @size, @size
    @drawQueue = []
    for laser in @manager.board.lasers
      @laser laser
    for x in [0..9]
      for y in [0..9]
        if e = @manager.getEntityAt(x, y)
          @[e.constructor.name.toLowerCase()](e)
    for fn in @drawQueue
      fn.apply(this, [])
  
  drawImage : (name, x, y) ->
    ImageManager.draw(name, @pen, x*@scale, y*@scale, @scale, @scale)
  
  laser : (e) ->
    lilLaser = (angle, length) =>
      @pen.save()
      
      @pen.translate((sx+t[0])*@scale, (sy+t[1])*@scale)
      @pen.rotate(angle)

      length = Math.min(length*@scale, 500)

      i = ImageManager.get("laser-long")
      z = UI.zoom() / 500
      @pen.drawImage(i, 0, 0, length, 25, 0, -12.5*z, length, 25*z)
      @pen.restore()
    
    len = ([ex, ey]) ->
      Math.abs(if sx == ex then sy-ey else sx-ex)
    
    for segment in e.segments
      angle = (segment.direction-1) * Math.PI/2
      [sx, sy] = segment.start.position
      if segment.start.type is Constants.EntityType.START
        l = if segment.end?.position then len(segment.end.position) + 1 else 11
        t = [0.5, 0.5]
        switch segment.direction
          when Constants.LaserDirection.S then t[1] = -0.5
          when Constants.LaserDirection.E then t[0] = -0.5
        lilLaser(angle, l, t)
      else if segment.end and segment.end.type isnt Constants.EntityType.END
        l = len(segment.end.position)
        t = [0.5, 0.5]
        lilLaser(angle, l)
      else if not segment.end or segment.end.type is Constants.EntityType.END
        t = [0.5, 0.5]
        lilLaser(angle, 10)
    

  block : (e) ->
    [x,y] = e.position
    @drawImage "block", x, y
    
  mirror : (e) ->
    [x, y] = e.position
    @pen.save()
    @pen.translate((x+0.5) * @scale, (y+0.5) * @scale)
    @pen.rotate(Math.PI/2 * (e.orientation-1))
    @drawImage "mirror", -0.5, -0.5
    @pen.restore()
  
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

  hoverHandler : (e) =>
    @clearLast()

    return if UI.zoomLevel > 1

    @lastMouseMove = [x,y] = @coordsToSquare e
        
    @fp.strokeStyle = '#00ff00' # ugly color for debugging
    @fp.strokeRect x*@scale+2, y*@scale+2, @scale-4, @scale-4
    
    # display tool
    if !@manager.getEntityAt(x, y) and UI.tool
      @pen = @fp
      @[UI.tool.toLowerCase()](new (window[UI.tool])([x,y], 1, true))
    
  clickHandler : (e) =>
    return if UI.zoomLevel > 1
    
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
  zoomLevel : 0
  plots     : []
  tool      : false
  dims      : [0, 0]
  localPlot : false
  localDiv  : false
  sprintTime: false
  nav       : false
  zoomLevels : [500, 400, 300, 200, 100]
  
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
      prev = @zoom() / 500.0
      if delta < 0
        @zoomLevel += 1 if @zoomLevel < 4
      else if @zoomLevel > 0
        @zoomLevel -= 1
      curr = @zoom() / 500.0  
      
      # < 1 if zoomed in
      d = @nav.draggable()                  # pretend going from 1 to 0.75
      o = d.offset()                        # -100, -100
      centerX = e.pageX         # 1000
      centerY = e.pageY
      oldX = (centerX - o.left) / prev      # 1100
      oldY = (centerY - o.top)  / prev      # 1100
      
      x = oldX*curr + o.left
      y = oldY*curr + o.top
      o.left += centerX - x
      o.top  += centerY - y
      
      d.offset(o)
      @resizePlots()
      
    $("#give-up").click => @showStartDialog()
      
    $("#palate li").click ->
      UI.tool = $(this).data("tool")
      $("#palate li").removeClass("selected")
      $(this).addClass("selected")
  
  zoom : () -> @zoomLevels[@zoomLevel]
  
  resizePlots : ->
    $("canvas").attr width: @zoom(), height: @zoom()
    for plot in @plots when plot
      plot.resize()
      d = @zoom() * 1.01
      css =
        left:        d*plot.manager.gridX
        top:         d*plot.manager.gridY
        width:       @zoom()
        height:      @zoom()
      $(plot.front).parent().css(css)
    @draw()
  
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
    
    if old = @plots[manager.id]
      $(old.front).parent().remove()
    @plots[manager.id] = p
    
    
    #testing stuff
    p.manager.addEntity(new Mirror([5,5], Constants.EntityOrient.NE))
    p.manager.addEntity(new Endpoint([5,0]))
    start = new Startpoint([0,5], Constants.LaserDirection.E)
    laser = new Laser('#F00', start)

    p.manager.addEntity(start)
    p.manager.addLaser(laser)

    p.drawTiles()
    p.drawEntities()
    
    @dims = [Math.max(@dims[0], 1+manager.gridX),
             Math.max(@dims[1], 1+manager.gridY)]
                      
    $div.css left: p.size*manager.gridX, top: p.size*manager.gridY
    @resizePlots()
    @scrollTo(@localDiv) if mine
