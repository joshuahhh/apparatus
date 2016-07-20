_ = require "underscore"


module.exports = Constraints = {}

class Constraints.VariableSet
  constructor: (@name, @startingValues={}) ->

  constructVariable: (variableName) ->
    this[variableName] = new c.Variable
      name: @name + '.' + variableName,
      value: @startingValues[variableName]

  constructVariables: (variableNames) ->
    variableNames.map(@constructVariable.bind(this))

  constrain: (solver) ->
    @getConstraints().forEach (constraint) ->
      solver.addConstraint(constraint)

class Constraints.Box extends Constraints.VariableSet
  constructor: (name, startingValues = {}) ->
    super(name, startingValues)
    @constructVariables(
      ['left', 'right', 'top', 'bottom', 'centerX', 'centerY', 'width', 'height']
    )

  getConstraints: ->
    [
      new c.Equation(@width, c.minus(@right, @left))
      new c.Equation(@height, c.minus(@bottom, @top))
      new c.Equation(c.minus(@right, @centerX), c.minus(@centerX, @left))
      new c.Equation(c.minus(@top, @centerY), c.minus(@centerY, @bottom))
      new c.Inequality(@left, c.LEQ, @right)
      new c.Inequality(@top, c.LEQ, @bottom)
    ]

  getBoundValues: ->
    {
      left: @left.value
      right: @right.value
      top: @top.value
      bottom: @bottom.value
    }

  constrainToBeInside: (otherBox, padding, solver) ->
    solver.addConstraint(new c.Inequality(@top, c.GEQ, c.plus(otherBox.top, padding)))
    solver.addConstraint(new c.Inequality(@bottom, c.LEQ, c.plus(otherBox.bottom, -padding)))
    solver.addConstraint(new c.Inequality(@left, c.GEQ, c.plus(otherBox.left, padding)))
    solver.addConstraint(new c.Inequality(@right, c.LEQ, c.plus(otherBox.right, -padding)))


Constraints.addAbsoluteValueToObjective = (objective, expr1, expr2, solver, weight=1) ->
  positivePart = new c.Variable()
  negativePart = new c.Variable()
  solver.addConstraint(new c.Inequality(positivePart, c.GEQ, 0))
  solver.addConstraint(new c.Inequality(negativePart, c.GEQ, 0))
  solver.addConstraint(new c.Equation(expr1, c.plus(expr2, c.minus(positivePart, negativePart))))

  toReturn = c.plus(objective, c.times(c.plus(positivePart, negativePart), weight))
  # toReturn = objective;
  return toReturn


Constraints.addPseudoQuadraticToObjective = (objective, expr1, expr2, solver, halfRange, step, weight=1) ->
  _.range(-halfRange, halfRange + 0.001, step).forEach (x) ->
    objective = Constraints.addAbsoluteValueToObjective(objective, expr1, c.plus(expr2, x), solver, weight)
  return objective
