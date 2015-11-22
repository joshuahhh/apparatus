_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"


# This is the user-facing "spread" function which generates spreads from arrays
# and numeric-range spreads.
module.exports = spread = (start, end, increment=1) ->
  if _.isArray(start)
    return new Dataflow.Spread(start)

  if !start? or !end?
    throw "Spread needs arguments: spread(start, end) or spread(start, end, increment) or spread(array)"
  if increment == 0
    throw "Spread increment cannot be 0"
  if !_.isFinite(increment)
    throw "Spread increment must be finite"

  n = (end - start) / increment
  array = (start + increment * i for i in [0 ... n])
  return new Dataflow.Spread(array)
