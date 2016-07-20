R = require "../View/R"
_ = require "underscore"

TreeLayout = require "./TreeLayout"


R.create "TreeDiagram",
  render: ->
    {tree, environment} = this.props
    style = {verticalAlign: 'top'}

    before = +(new Date())
    layout = new TreeLayout(tree)
    layout.resolve()
    console.log('laid out in', +(new Date()) - before)

    svgWidth = Math.max(
      _.max(layout.nodeShapes.map (nodeShape) => nodeShape.outerBox.right.value),
      _.max(layout.cloneShapes.map (cloneShape) => cloneShape.outerBox.right.value)) + 2
    svgHeight = Math.max(
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
            stroke: "#888888", strokeWidth: "2"
          }
      # nodes
      layout.nodeShapes.map (nodeShape) =>
        R.TreeDiagramNode {key: nodeShape.id, nodeShape: nodeShape}
      # clones
      layout.cloneShapes.map (cloneShape) =>
        R.TreeDiagramClone {key: cloneShape.id, cloneShape: cloneShape}

R.create "WigglyLine",
  render: ->
    {x1, y1, x2, y2} = this.props
    otherProps = _.omit this.props, 'x1', 'y1', 'x2', 'y2'

    R.g {},
      R.line _.extend({x1: x1, y1: y1, x2: x1, y2: y2 + 20}, otherProps)
      R.line _.extend({x1: x1, y1: y2 + 20, x2: x2, y2: y2 + 20}, otherProps)
      R.line _.extend({x1: x2, y1: y2 + 20, x2: x2, y2: y2}, otherProps)

R.create "TreeDiagramNode",
  render: ->
    {nodeShape} = this.props

    R.g {},
      R.rect {
          x: nodeShape.outerBox.left.value, y: nodeShape.outerBox.top.value,
          width: nodeShape.outerBox.width.value, height: nodeShape.outerBox.height.value,
          fill: "#F2F2F2",
          stroke: "black"
        }
      R.text {
          x: nodeShape.outerBox.centerX.value, y: nodeShape.outerBox.top.value + 2,
          style: {dominantBaseline: 'hanging', textAnchor: 'middle', fontSize: 8}
        }, nodeShape.localId

R.create "TreeDiagramClone",
  render: ->
    {cloneShape, environment} = this.props;

    R.g {},
      R.rect {
          x: cloneShape.innerBox.left.value, y: cloneShape.innerBox.top.value,
          width: cloneShape.innerBox.width.value, height: cloneShape.innerBox.height.value,
          fill: "none"
          stroke: "gray"
          strokeDasharray: 4
          strokeWidth: 1
        }
      R.g {transform: "translate(#{cloneShape.innerBox.right.value + 5}, #{cloneShape.innerBox.top.value + 2})"},
        R.text {style: {dominantBaseline: "hanging", fontSize: 8}},
          cloneShape.localId
        # R.text {style: {dominantBaseline: "hanging", fontSize: 8}, y: 10},
        #   cloning.symbolId
