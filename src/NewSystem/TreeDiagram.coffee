R = require "../View/R"
_ = require "underscore"

TreeLayout = require "./TreeLayout"

FOR_CAIRO = true
if FOR_CAIRO
  TEXT_ALIGN_MIDDLE = "middle"
  TEXT_ALIGN_BELOW = "top"  # or "hanging"
else
  TEXT_ALIGN_MIDDLE = "middle"
  TEXT_ALIGN_BELOW = "hanging"

FONT_FAMILY = "helvetica"

R.create "TreeDiagram",
  render: ->
    {tree} = this.props
    style = {verticalAlign: 'top'}

    before = +(new Date())
    layout = new TreeLayout(tree)
    layout.resolve()
    console.log('laid out in', +(new Date()) - before)

    svgWidth = Math.max(
      _.max(layout.nodeShapes.map (nodeShape) => nodeShape.outerBox.right.value),
      _.max(layout.cloneShapes.map (cloneShape) => cloneShape.outerBox.right.value)) + 2
    heightMultiplier = 1  # TODO: 1.5 is hack to stick arcs in; not too cool
    svgHeight = heightMultiplier * Math.max(
      _.max(layout.nodeShapes.map (nodeShape) => nodeShape.outerBox.bottom.value),
      _.max(layout.cloneShapes.map (cloneShape) => cloneShape.outerBox.bottom.value)) + 2

    R.svg {width: svgWidth, height: svgHeight, style: style},
      # edges
      layout.nodeShapes.map (nodeShape) =>
        nodeShape.node.childIds.map (childId) =>
          childShape = layout.getNodeShapeById(childId)
          R.WigglyLine {
            key: "#{nodeShape.id} - #{childId}",
            x1: childShape.outerBox.centerX.value, y1: childShape.outerBox.top.value,
            x2: nodeShape.outerBox.centerX.value, y2: nodeShape.outerBox.bottom.value,
            yZag: nodeShape.childConnectorZagY.value
            stroke: "#888888", strokeWidth: "2"
          }
      layout.nodeShapes.map (nodeShape) =>
        for own linkKey, linkTargetId of nodeShape.node.linkTargetIds
          targetShape = layout.getNodeShapeById(linkTargetId)
          horOffset = targetShape.outerBox.centerX.value - nodeShape.outerBox.centerX.value
          d = "M #{nodeShape.outerBox.centerX.value} #{nodeShape.outerBox.centerY.value}
               C #{nodeShape.outerBox.centerX.value} #{nodeShape.outerBox.centerY.value + Math.abs(horOffset) / 2}
                 #{targetShape.outerBox.centerX.value} #{targetShape.outerBox.centerY.value + Math.abs(horOffset) / 2}
                 #{targetShape.outerBox.centerX.value} #{targetShape.outerBox.centerY.value}"
          fakePath = document.createElementNS("http://www.w3.org/2000/svg", "path")
          fakePath.setAttributeNS(null, "d", d)
          fakePathLength = fakePath.getTotalLength()
          midpoint = fakePath.getPointAtLength(fakePathLength / 2)
          R.g {},
            R.path {
              key: "#{nodeShape.id} - #{linkTargetId}",
              d: d
              fill: "none"
              stroke: "#882222", strokeWidth: "2"
            }
            R.text {
              x: midpoint.x
              y: midpoint.y - 3
              fill: "#882222"
              style: {textAnchor: "middle", alignmentBaseline: TEXT_ALIGN_MIDDLE, fontSize: "30", fontFamily: FONT_FAMILY}
            },
              if horOffset > 0 then ">" else "<"
            R.text {
              x: midpoint.x
              y: midpoint.y + 15
              fill: "#882222"
              style: {textAnchor: "middle", alignmentBaseline: TEXT_ALIGN_MIDDLE, fontSize: "10", fontFamily: FONT_FAMILY}
            },
              linkKey

      # nodes
      layout.nodeShapes.map (nodeShape) =>
        R.TreeDiagramNode {key: nodeShape.id, nodeShape: nodeShape}
      # clones
      layout.cloneShapes.map (cloneShape) =>
        R.TreeDiagramClone {key: cloneShape.id, cloneShape: cloneShape}

R.create "WigglyLine",
  render: ->
    {x1, y1, x2, y2, yZag} = this.props
    otherProps = _.omit this.props, 'x1', 'y1', 'x2', 'y2'

    R.g {style: {shapeRendering: "crispEdges"}},
      R.line _.extend({x1: x1, y1: y1, x2: x1, y2: yZag}, otherProps)
      R.line _.extend({x1: x1, y1: yZag, x2: x2, y2: yZag}, otherProps)
      R.line _.extend({x1: x2, y1: yZag, x2: x2, y2: y2}, otherProps)

R.create "TreeDiagramNode",
  render: ->
    {nodeShape} = this.props

    R.g {onClick: -> console.log nodeShape.node},
      R.rect {
          x: nodeShape.outerBox.left.value, y: nodeShape.outerBox.top.value,
          width: nodeShape.outerBox.width.value, height: nodeShape.outerBox.height.value,
          fill: "#F2F2F2",
          stroke: "black",
          style: {shapeRendering: "crispEdges"}
        }
      R.text {
          x: nodeShape.outerBox.centerX.value, y: nodeShape.outerBox.top.value + 2,
          style: {alignmentBaseline: TEXT_ALIGN_BELOW, textAnchor: 'middle', fontSize: 8, fontFamily: FONT_FAMILY}
        }, nodeShape.localId

R.create "TreeDiagramClone",
  render: ->
    {cloneShape} = this.props;

    R.g {},
      R.rect {
          x: cloneShape.innerBox.left.value, y: cloneShape.innerBox.top.value,
          width: cloneShape.innerBox.width.value, height: cloneShape.innerBox.height.value,
          fill: "none"
          stroke: "gray"
          strokeDasharray: 4
          strokeWidth: 1
          style: {shapeRendering: "crispEdges"}
        }
      # R.g {transform: "translate(#{cloneShape.innerBox.right.value + 5}, #{cloneShape.innerBox.top.value + 2})"},
      #   R.text {style: {alignmentBaseline: TEXT_ALIGN_BELOW, fontSize: 8}},
      #     cloneShape.localId
      #   R.text {style: {alignmentBaseline: TEXT_ALIGN_BELOW, fontSize: 8}, y: 10},
      #     cloneShape.symbolId
      R.g {transform: "translate(#{cloneShape.outerBox.left.value + 1}, #{cloneShape.outerBox.top.value + 1})"},
        R.text {
            style: {alignmentBaseline: TEXT_ALIGN_BELOW, textAnchor: 'start', fontSize: 8, fontFamily: FONT_FAMILY}
          },
          cloneShape.symbolId
        R.text {
            style: {alignmentBaseline: TEXT_ALIGN_BELOW, textAnchor: 'start', fontSize: 8, fontStyle: 'italic', fontFamily: FONT_FAMILY}
            y: 10
          },
          cloneShape.localId
