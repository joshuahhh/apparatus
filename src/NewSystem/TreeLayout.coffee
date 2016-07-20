_ = require 'underscore'

Constraints = require './Constraints'
{Box, addPseudoQuadraticToObjective} = Constraints


byType = (funcForEachType) -> (obj) -> funcForEachType[obj.type](obj)

splitPath = (path) ->
  lastSlashIdx = path.lastIndexOf('/')
  if lastSlashIdx != -1
    [path.slice(0, lastSlashIdx), path.slice(lastSlashIdx + 1)]
  else
    [null, path]

defaultOptions =
  nodeWidth: 60
  nodeHeight: 30
  cloneLabelWidth: 150
  verticalSpacing: 40
  paddingBetweenclones: 10
  cloneLabelExtractor: (clone) -> clone.localId # + '\n' + clone.symbolId

textWidth = (text) ->
  maxChar = _.max(_.pluck(text.split('\n'), 'length'))
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
        outerBox: new Box(node.id + '.outer')
        subtreeLeft: new c.Variable(node.id + '.subtreeLeft')
        subtreeRight: new c.Variable(node.id + '.subtreeRight')
      }

  getNodeShapeById: (id) ->
    _.find @nodeShapes, {id: id}

  getCloneShapeById: (id) ->
    _.find @cloneShapes, {id: id}

  addClone: (id) ->
    if @getCloneShapeById(id)
      return

    [parentCloneId, localId] = splitPath(id)

    @cloneShapes.push
      id: id
      localId: localId
      parentCloneId: parentCloneId
      innerBox: new Box(id + '.inner')
      outerBox: new Box(id + '.outer')

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

      lastChild = null
      node.childIds.forEach (childId) =>
        child = @getNodeShapeById(childId)

        ineq c.plus(box.bottom, 2 * @options.verticalSpacing), c.LEQ, child.outerBox.top
        objectiveExpression = objectiveExpression.plus(c.minus(child.outerBox.top, box.bottom))

        objectiveExpression = addPseudoQuadraticToObjective(
          objectiveExpression,
          box.centerX, child.outerBox.centerX, solver, 600, 50)

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
      eq innerBox.top, outerBox.top
      eq innerBox.bottom, outerBox.bottom
      # TODO: hacky text width calculation follows:
      cloneLabelWidth = textWidth(@options.cloneLabelExtractor(cloneShape))
      eq c.plus(innerBox.right, cloneLabelWidth), outerBox.right

      if cloneShape.parentCloneId
        parentCloneShape = @getCloneShapeById(cloneShape.parentCloneId)
        cloneShape.outerBox.constrainToBeInside(parentCloneShape.innerBox, 10, solver)


    objectiveVariable = new c.Variable()
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression))
    solver.optimize(objectiveVariable)
    solver.resolve()
