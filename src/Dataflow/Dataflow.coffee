_ = require "underscore"
ComputationManager = require "./ComputationManager"
Util = require "../Util/Util"


computationManager = new ComputationManager()


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
    @_evaluateFull = computationManager.memoize => @fn()

    @valid = false

  # run does the asSpread thing, but if the value is a spread, it reports it
  # upwards so that a higher level can distribute over the spread.
  run: Util.decorate 'Cell::run', ->
    computationManager.run =>
      value = @_evaluateFull()
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
  memoize: (fn) -> computationManager.memoize(fn)
  Cell
}
