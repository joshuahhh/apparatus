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


# A Dataflow.cell is a boxed-up version of a function which handles:
#   * caching of results during a larger evaluation
#   * calculation of spreads.
# A cell is not a primary source of truth in the scene graph. Rather, it is part
# of the real-time computation system.

cell = (fn) ->

  # These are the workhorse functions that together evaluate the cell.

  runFn = ->
    try
      return fn() if dynamicScope.context.shouldThrow
      return dynamicScope.with {shouldThrow: true}, fn
    catch error
      if error instanceof UnresolvedSpreadError
        return distributeAcrossSpread(error.spread)
      else
        throw error

  distributeAcrossSpread = (spread) ->
    currentSpreadEnv = dynamicScope.context.spreadEnv
    items = _.map spread.items, (item, index) ->
      spreadEnv = currentSpreadEnv.assign(spread, index)
      return dynamicScope.with {spreadEnv}, runFn
    return new Spread(items, spread.origin)


  evaluateFull = ->
    return dynamicScope.with {spreadEnv: SpreadEnv.empty}, runFn

  evaluateFull = computationManager.memoize(evaluateFull)


  # resolve will recursively try to resolve value in the current spread
  # environment until it gets to a non-Spread or a Spread that is not in the
  # environment.
  resolve = (value) ->
    currentSpreadEnv = dynamicScope.context.spreadEnv
    return currentSpreadEnv.resolve(value)


  # "Public" methods.
  asSpread = ->
    if !computationManager.isRunning
      return computationManager.run(asSpread)
    value = evaluateFull()
    value = resolve(value)
    return value

  cellFn = ->
    if !computationManager.isRunning
      return computationManager.run(cellFn)
    value = asSpread()
    if dynamicScope.context.shouldThrow and value instanceof Spread
      throw new UnresolvedSpreadError(value)
    return value

  # Package it up.
  cellFn.asSpread = asSpread
  return cellFn


module.exports = Dataflow = {
  run: (callback) -> computationManager.run(callback)
  currentSpreadEnv: -> dynamicScope.context.spreadEnv
  memoize: (fn) -> computationManager.memoize(fn)
  cell, Spread, SpreadEnv, UnresolvedSpreadError
}
