_ = require "underscore"
Util = require "../Util/Util"


# INCREDIBLY STUPID IMPLEMENTATION
# PLEASE DON'T THINK I'M STUPID
# (I USUALLY DON'T THINK I'M STUPID)
class Spread
  constructor: (@values) ->

  # Assuming this is a spread of spreads of Xs, turns it into a spread of Xs
  # NOTE: for now, we assert that the origins of the top-level spread are
  # different than the origins in the lower-level-spreads
  join: () ->
    valuesToReturn = []
    for [env1, value1] in @values
      # We assume value1 is a spread
      for [env2, value2] in value1.values
        valuesToReturn.push([mergeMaps(env1, env2), value2])
    return new Spread(valuesToReturn)

  # If this is a spread of arrays, and otherSpread is a spread of arrays, and
  # concat = [].concat.bind([]), then this produces
  # Monadic.Spread.multimap(concat, this, otherSpread).
  _concat: (otherSpread) ->
    valuesToReturn = []
    for [env1, value1] in @values
      for [env2, value2] in otherSpread.values
        if mapsAgree(env1, env2)
          valuesToReturn.push([mergeMaps(env1, env2), value1.concat(value2)])
    return new Spread(valuesToReturn)

  map: (func) ->
    return new Spread(@values.map(([env, value]) -> [env, func(value)]))

  items: ->
    return _.pluck(@values, 1)


  # CONSTRUCTORS

  @fromArray: (items, returnNewOrigin = false) ->
    newOrigin = Util.generateId()
    values = items.map (item, index) -> [new Map([[newOrigin, index]]), item]
    spread = new Spread(values)
    return if returnNewOrigin then [spread, newOrigin] else spread

  @fromValue: (value) ->
    return new Spread([[new Map(), value]])



  # OPERATORS

  @product: (spreads) ->
    reducer = (a, b) -> a._concat(b.map((value) -> [value]))
    spreads.reduce(reducer, Spread.fromValue([]))

  @multimap: (args, func) ->
    Spread.product(args).map((tuple) -> func.apply(null, tuple))

  @multibind: (args, func) ->
    Spread.multimap(args, func).join()

mapsAgree = (map1, map2) ->
  Array.from(map1.entries()).every ([key, value]) -> !map2.has(key) or map2.get(key) == value

mergeMaps = (map1, map2) ->
  toReturn = new Map(map1)
  map2.forEach (value, key) -> toReturn.set(key, value)
  return toReturn

module.exports = Monadic = {Spread}
