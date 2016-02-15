_ = require "underscore"


# A spread is an array annotated with an origin (conventionally a
# Model.Attribute). Spreads can be nested: you can have a spread of spreads.

# QUESTION: Why is the origin of a spread an ATTRIBUTE, rather than a "spread
# creator instance" (use of the `spread` function?)

# ANSWER: Because, in the current system, a spread creator IS an attribute. You
# can't say `spread(0, 3) + spread(0, 3)` -- each use of `spread` CREATES a new
# spread, but you can't add spreads to each other! You can only add attributes
# to each other which happen to be spread.

# (This seems off to me. There shouldn't be a difference between saying:
#   Var1: spread(0, 3)
#   Var2: X + 1
# and
#   Var2: spread(0, 3) + 1,
# right?)

module.exports = class Spread
  constructor: (@items, @origin) ->

  # Recursively converts a spread to an array. So if I'm a nested spread,
  # toArray will return a nested array.
  toArray: ->
    _.map @items, (item) ->
      if item instanceof Spread
        item.toArray()
      else
        item

  flattenToArray: ->
    _.flatten(@toArray())
