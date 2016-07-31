R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "Thumbnail",
  propTypes:
    symbol: Object

  render: ->
    {symbol} = @props
    R.div {className: "Thumbnail"},
      R.Picture {symbol}





R.create "Picture",
  contextTypes:
    project: Model.Project
    hoverManager: R.HoverManager

  propTypes:
    symbol: Object

  render: ->
    R.HTMLCanvas {
      draw: @_draw
    }

  _draw: (ctx) ->
    project = @context.project
    hoverManager = @context.hoverManager
    {symbol} = @props
    viewMatrix = @_viewMatrix()
    element = symbol.getTree().getNodeById("root").bundle

    tree = project.editingTree()

    highlight = (graphic) ->
      particularElement = graphic.particularElement
      if hoverManager.controllerParticularElement?.isAncestorOf(particularElement, tree)
        return {color: "#c00", lineWidth: 2.5}
      if project.selectedParticularElement?.isAncestorOf(particularElement, tree)
        return {color: "#09c", lineWidth: 2.5}
      if hoverManager.hoveredParticularElement?.isAncestorOf(particularElement, tree)
        return {color: "#0c9", lineWidth: 2.5}

    renderOpts = {ctx, viewMatrix, highlight}

    for graphic in element.allGraphics()
      graphic.render(renderOpts)

  _viewMatrix: ->
    {symbol} = @props
    {width, height} = @_size()
    screenMatrix = new Util.Matrix(0.1, 0, 0, -0.1, width / 2, height / 2)
    symbolViewMatrix = symbol.viewMatrix
    # console.log(symbol, symbolViewMatrix)
    return screenMatrix.compose(symbolViewMatrix)

  _size: ->
    return @_cachedSize if @_cachedSize
    el = R.findDOMNode(@)
    rect = el.getBoundingClientRect()
    {width, height} = rect
    return @_cachedSize = {width, height}
