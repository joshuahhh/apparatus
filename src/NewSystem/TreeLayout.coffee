_ = require "underscore"

Constraints = require "./Constraints"
{Box, addPseudoQuadraticToObjective} = Constraints


# With parent node wanting to be over middle of children: 11.4 sec
# With parent node wanting to be over first child: 1.1 sec


byType = (funcForEachType) -> (obj) -> funcForEachType[obj.type](obj)

splitPath = (path) ->
  lastSlashIdx = path.lastIndexOf("/")
  if lastSlashIdx != -1
    [path.slice(0, lastSlashIdx), path.slice(lastSlashIdx + 1)]
  else
    [null, path]

defaultOptions =
  nodeWidth: 40
  nodeHeight: 30
  cloneLabelWidth: 150
  verticalSpacing: 20
  paddingBetweenclones: 10
  cloneLabelExtractor: (clone) -> clone.localId + "\n" + clone.symbolId

textWidth = (text) ->
  maxChar = _.max(_.pluck(text.split("\n"), "length"))
  return 10 + maxChar * 4

module.exports = class TreeLayout
  constructor: (@tree, options={}) ->
    @options = _.defaults(options, defaultOptions)

    @cloneShapes = []  # fill in with @addClone

    @nodeShapes = @tree.nodes.map (node) =>
      [parentCloneId, localId] = splitPath(node.id)
      if parentCloneId
        @addClone(parentCloneId)

      return {
        node: node
        id: node.id
        localId: localId
        parentCloneId: parentCloneId
        outerBox: new Box(node.id + ".outer")
        childConnectorZagY: new c.Variable({name: node.id + '.' + 'zag'})
        # subtreeLeft: new c.Variable(node.id + ".subtreeLeft")
        # subtreeRight: new c.Variable(node.id + ".subtreeRight")
      }

  getNodeShapeById: (id) ->
    _.find @nodeShapes, {id: id}

  getCloneShapeById: (id) ->
    _.find @cloneShapes, {id: id}

  shapesOfDeparture: (id1, id2) ->
    id1Path = id1.split("/")
    id2Path = id2.split("/")

    numCommonComponents = 0
    while true
      if id1Path[numCommonComponents] == id2Path[numCommonComponents]
        numCommonComponents++
      else
        if numCommonComponents == id1Path.length - 1
          shape1 = @getNodeShapeById(id1)
        else
          shape1 = @getCloneShapeById(id1Path.slice(0, numCommonComponents + 1).join("/"))

        if numCommonComponents == id2Path.length - 1
          shape2 = @getNodeShapeById(id2)
        else
          shape2 = @getCloneShapeById(id2Path.slice(0, numCommonComponents + 1).join("/"))

        return [shape1, shape2]

  addClone: (id) ->
    if @getCloneShapeById(id)
      return

    [parentCloneId, localId] = splitPath(id)

    @cloneShapes.push
      id: id
      localId: localId
      parentCloneId: parentCloneId
      symbolId: _.find(@tree.cloneOrigins, {id: id}).symbolId
      innerBox: new Box(id + ".inner")
      outerBox: new Box(id + ".outer")

    if parentCloneId
      @addClone(parentCloneId)

  resolve: ->
    solver = new c.SimplexSolver()
    objectiveExpression = new c.Expression(0)

    eq = (x, y) -> solver.addConstraint(new c.Equation(x, y))
    ineq = (x, r, y) -> solver.addConstraint(new c.Inequality(x, r, y))

    @nodeShapes.forEach (nodeShape) =>
      box = nodeShape.outerBox
      node = nodeShape.node

      box.constrain(solver)

      eq box.width, @options.nodeWidth
      eq box.height, @options.nodeHeight

      ineq box.left, c.GEQ, 1
      ineq box.top, c.GEQ, 1

      lastChildShape = null
      node.childIds.forEach (childId) =>
        childShape = @getNodeShapeById(childId)

        [nodeDepartShape, childDepartShape] = @shapesOfDeparture(node.id, childShape.id)
        ineq c.plus(nodeDepartShape.outerBox.bottom, 2 * @options.verticalSpacing), c.LEQ, childDepartShape.outerBox.top

        # eq c.minus(nodeDepartShape.outerBox.bottom, childShape.childConnectorZagY), c.minus(childShape.childConnectorZagY, childDepartShape.outerBox.top)
        ineq nodeShape.childConnectorZagY, c.LEQ, c.divide(c.plus(nodeDepartShape.outerBox.bottom, childDepartShape.outerBox.top), 2)

        objectiveExpression = objectiveExpression.plus(c.minus(childDepartShape.outerBox.top, nodeDepartShape.outerBox.bottom))

        # objectiveExpression = addPseudoQuadraticToObjective(
        #   objectiveExpression,
        #   box.centerX, childShape.outerBox.centerX, solver, 600, 50)
        if not lastChildShape
          eq box.centerX, childShape.outerBox.centerX

        if lastChildShape
          [lastChildDepartShape, nodeDepartShape1] = @shapesOfDeparture(lastChildShape.id, nodeShape.id)
          [childDepartShape, nodeDepartShape2] = @shapesOfDeparture(childShape.id, nodeShape.id)
          ineq childDepartShape.outerBox.left, c.GEQ, c.plus(lastChildDepartShape.outerBox.right, 10)
        lastChildShape = childShape

        # HEURISTIC: When you have a parent/child node/node relationship, this
        # establishes a corresponding vertical relationship between any
        # clonings/nodes which differ between the parent and child. This
        # heuristic will FAIL if following children ever pops you out of a
        # cloning and then back into it. Meh. Heuristics were made to be broken.

      if nodeShape.parentCloneId
        parentCloneShape = @getCloneShapeById(nodeShape.parentCloneId)
        nodeShape.outerBox.constrainToBeInside(parentCloneShape.innerBox, 10, solver)

    @cloneShapes.forEach (cloneShape) =>
      {innerBox, outerBox} = cloneShape

      innerBox.constrain(solver)
      outerBox.constrain(solver)

      ineq outerBox.left, c.GEQ, 1
      ineq outerBox.top, c.GEQ, 2

      objectiveExpression = objectiveExpression.plus(innerBox.width)
      objectiveExpression = objectiveExpression.plus(innerBox.height)


      eq innerBox.left, outerBox.left
      eq innerBox.right, outerBox.right
      eq innerBox.top, c.plus(outerBox.top, 20)
      eq innerBox.bottom, outerBox.bottom
      # TODO: hacky text width calculation follows:
      # cloneLabelWidth = textWidth(@options.cloneLabelExtractor(cloneShape))
      # # eq c.plus(innerBox.right, cloneLabelWidth), outerBox.right
      # eq c.minus(innerBox.left, cloneLabelWidth), outerBox.left

      if cloneShape.parentCloneId
        parentCloneShape = @getCloneShapeById(cloneShape.parentCloneId)
        cloneShape.outerBox.constrainToBeInside(parentCloneShape.innerBox, 10, solver)


    objectiveVariable = new c.Variable()
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression))
    solver.optimize(objectiveVariable)
    solver.resolve()
