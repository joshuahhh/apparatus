_ = require "underscore"
ComputationManager = require "./ComputationManager"
DynamicScope = require "./DynamicScope"
Spread = require "./Spread"
SpreadEnv = require "./SpreadEnv"
Util = require "../Util/Util"

# TODO: CHROME HACKAGE
Error.stackTraceLimit = undefined

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


  evaluateFull = computationManager.memoize ->
    Util.log 'cell -- evaluateFull'
    return dynamicScope.with {spreadEnv: SpreadEnv.empty}, runFn


  # resolve will recursively try to resolve value in the current spread
  # environment until it gets to a non-Spread or a Spread that is not in the
  # environment.
  resolve = (value) ->
    currentSpreadEnv = dynamicScope.context.spreadEnv
    return currentSpreadEnv.resolve(value)


  # "Public" methods.
  asSpread = ->
    Util.log 'cell -- asSpread'
    computationManager.run ->
      value = evaluateFull()
      value = resolve(value)
      return value

  cellFn = ->
    Util.log 'cell -- cellFn'
    computationManager.run ->
      value = asSpread()
      if dynamicScope.context.shouldThrow and value instanceof Spread
        throw new UnresolvedSpreadError(value)
      return value

  # Package it up.
  cellFn.asSpread = asSpread
  return cellFn


class Cell
  constructor: (@fn, @label) ->
    @_secretInternalCell = cell(@fn)

  call: Util.decorate 'Cell::call', ->
    Util.log "We're in Cell with label '#{@label}'"
    return @_secretInternalCell()

  asSpread: Util.decorate 'Cell::asSpread', ->
    return @_secretInternalCell.asSpread()


module.exports = Dataflow = {
  run: (callback) -> computationManager.run(callback)
  currentSpreadEnv: -> dynamicScope.context.spreadEnv
  memoize: (fn) -> computationManager.memoize(fn)
  Cell, Spread, SpreadEnv, UnresolvedSpreadError
}
