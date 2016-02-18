_ = require "underscore"
ComputationManager = require "./ComputationManager"
DynamicScope = require "./DynamicScope"
Spread = require "./Spread"
SpreadEnv = require "./SpreadEnv"
Util = require "../Util/Util"


computationManager = new ComputationManager()

dynamicScope = new DynamicScope {
  # The current spread environment.
  spreadEnv: SpreadEnv.empty

  # Whether we are evaluating a top-level request from outside the Dataflow
  # system or a lower-level evaluation. (This matters because the top level has
  # the responsibility of gathering all the spreads which occur further down and
  # then distributing the computation over all of them.)
  topLevel: true
}

class UnresolvedSpreadError
  constructor: (@spread) ->
    Util.log('%cConstructing UnresolvedSpreadError', 'color:orange; background:blue; font-size: 16pt', @spread)


# IMPORTANT INVARIANT: if A depends on B, and B is invalid, then A is invalid.
#   This is maintained as follows:
#     Everyone starts invalid
#     A calculation occurs which makes a cell valid only if all of the cells it
#       depends on are already valid.
#     Invalidation of a cell will immediately cause cells which depend on it to
#       be invalidated.

# A Dataflow.cell is a boxed-up version of a function which handles:
#   * caching of results during a larger evaluation
#   * calculation of spreads.
# A cell is not stored as part of the scene graph. Rather, it is part of the
# real-time computation system.

class Cell
  constructor: (@fn, @dependersGetter) ->
    @_evaluateFull = Util.decorate 'Cell::_evaluteFull', computationManager.memoize =>
      return dynamicScope.with {spreadEnv: SpreadEnv.empty}, @_runFn.bind(this)

    @valid = false

    # @origin = (new Error).stack()

  # These are the workhorse functions that together evaluate the cell.

  _runFn: Util.decorate 'Cell::_runFun', ->
    Util.log dynamicScope.context
    try
      # Ensure that topLevel is false...
      if not dynamicScope.context.topLevel
        return @fn()
      else
        return dynamicScope.with {topLevel: false}, @fn
    catch error
      if error instanceof UnresolvedSpreadError
        return @_distributeAcrossSpread(error.spread)
      else
        throw error

  _distributeAcrossSpread: Util.decorate 'Cell::_distributeAcrossSpread', (spread) ->
    Util.log dynamicScope.context
    currentSpreadEnv = dynamicScope.context.spreadEnv
    items = _.map spread.items, (item, index) =>
      spreadEnv = currentSpreadEnv.assign(spread, index)
      return dynamicScope.with {spreadEnv}, @_runFn.bind(this)
    return new Spread(items, spread.origin)


  # asSpread returns the simplest representation of the cell in the current
  # spreadEnv: just evaluate the spread fully and then resolve using the
  # spreadEnv.
  asSpread: Util.decorate 'Cell::asSpread', ->
    Util.log dynamicScope.context
    computationManager.run =>
      value = @_evaluateFull()
      currentSpreadEnv = dynamicScope.context.spreadEnv
      value = currentSpreadEnv.resolve(value)
      return value

  # run does the asSpread thing, but wrapped in a check...
  run: Util.decorate 'Cell::run', ->
    Util.log dynamicScope.context
    computationManager.run =>
      value = @asSpread()
      if (not dynamicScope.context.topLevel) and value instanceof Spread
        throw new UnresolvedSpreadError(value)
      @valid = true
      return value

  invalidate: ->
    if not @valid
      # by the invariant, we can assume all dependers are already invalid
    else
      @valid = false
      dependers = @dependersGetter()
      dependers.forEach((depender) -> depender.invalidate())


module.exports = Dataflow = {
  run: (callback) -> computationManager.run(callback)
  currentSpreadEnv: -> dynamicScope.context.spreadEnv
  memoize: (fn) -> computationManager.memoize(fn)
  Cell, Spread, SpreadEnv, UnresolvedSpreadError
}
