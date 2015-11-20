_ = require "underscore"
ComputationManager = require "./ComputationManager"
DynamicScope = require "./DynamicScope"
Spread = require "./Spread"
SpreadEnv = require "./SpreadEnv"


computationManager = new ComputationManager()

dynamicScope = new DynamicScope {
  # The current spread environment.
  spreadEnv: SpreadEnv.empty

  # Whether or not cells should throw an UnresolvedSpreadError if they
  # encounter a spread that is not in the current spread environment.
  shouldThrow: false
}

class UnresolvedSpreadError
  constructor: (@spread) ->



# resolve will recursively try to resolve value in the current spread
# environment until it gets to a non-Spread or a Spread that is not in the
# environment.
resolve: (value) =>
  currentSpreadEnv = dynamicScope.context.spreadEnv
  return currentSpreadEnv.resolve(value)

class Cell
  constructor: (@fn) ->

  # These are the workhorse functions that together evaluate the cell.

  _runFn: =>
    try
      return @fn() if dynamicScope.context.shouldThrow
      return dynamicScope.with {shouldThrow: true}, @fn
    catch error
      if error instanceof UnresolvedSpreadError
        return _distributeAcrossSpread(error.spread)
      else
        throw error

  _distributeAcrossSpread: (spread) =>
    currentSpreadEnv = dynamicScope.context.spreadEnv
    items = _.map spread.items, (item, index) ->
      spreadEnv = currentSpreadEnv.assign(spread, index)
      return dynamicScope.with {spreadEnv}, @_runFn
    return new Spread(items, spread.origin)

  _evaluateFull: computationManager.memoize =>
    return dynamicScope.with {spreadEnv: SpreadEnv.empty}, @_runFn

  asSpread: ->
    computationManager.run ->
      value = evaluateFull()
      value = resolve(value)
      return value

  run: ->
    computationManager.run ->
      value = asSpread()
      if dynamicScope.context.shouldThrow and value instanceof Spread
        throw new UnresolvedSpreadError(value)
      return value

module.exports = Dataflow = {
  run: (callback) -> computationManager.run(callback)
  currentSpreadEnv: -> dynamicScope.context.spreadEnv
  memoize: (fn) -> computationManager.memoize(fn)
  cell, Spread, SpreadEnv, UnresolvedSpreadError
}
