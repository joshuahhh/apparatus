Spread = require "./Spread"

# TODO: This should have tests for isEqualTo and contains

# SpreadEnv tells you about where you are inside spreads. If your circle's
# x-position is set to myXSpread and its y-position is set to myYSpread, then,
# when you're drawing an instance of the circle, you want to know where you are
# in those two spreads so you can come up with specific values for the x- and
# y-positions. Each SpreadEnv handles a single spread origin, but they can be
# nested into hierarchies. For instance:
#
# SpreadEnv1
#   origin: XAttribute
#   index: 3
#   parent:
#     SpreadEnv2
#       origin: YAttribute
#       index: 5
#       parent:
#         SpreadEnv.empty
#           origin: undefined
#           index: undefined
#           parent: undefined
#
# In this environment, spreads with origin XAttribute will be resolved with
# index 3, and spreads with origin YAttribute will be resolved with index 5.

module.exports = class SpreadEnv
  constructor: (@parent, @origin, @index) ->

  # Returns the location in a spread which the SpreadEnv is "at" (an integer
  # index), or `undefined` if the SpreadEnv is not in the spread.
  lookup: (spread) ->
    if spread.origin == @origin
      return @index
    return @parent?.lookup(spread)

  # Returns the particular value the SpreadEnv is "at", given a value which
  # might be spread in various directions.
  resolve: (value) ->
    if value instanceof Spread
      index = @lookup(value)
      if index?
        value = value.items[index]
        return @resolve(value)
    return value

  # Like resolve, but will take index 0 if the spread cannot be found.
  resolveWithDefault: (value) ->
    if value instanceof Spread
      index = @lookup(value) ? 0
      value = value.items[index]
      return @resolveWithDefault(value)
    return value


  # Note: assign is not a mutation, it returns a new SpreadEnv where spread is
  # assigned to index.
  assign: (spread, index) ->
    return new SpreadEnv(this, spread.origin, index)

  # Not sure if this is used? Not sure if this is correct.
  isEqualTo: (spreadEnv) ->
    return false unless spreadEnv?
    return false unless @origin == spreadEnv.origin and @index == spreadEnv.index
    return true if !@parent and !spreadEnv.parent
    return @parent.isEqualTo(spreadEnv.parent)

  # Not sure if this is used? Not sure if this is correct.
  contains: (spreadEnv) ->
    return false unless spreadEnv?
    return true if @isEqualTo(spreadEnv)
    return @contains(spreadEnv.parent)


SpreadEnv.empty = new SpreadEnv()
