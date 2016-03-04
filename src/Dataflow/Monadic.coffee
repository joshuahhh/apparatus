_ = require "underscore"
Util = require "../Util/Util"


# Note: The main rule that the envs in a spread must obey is that no env can be
# a superset of another.

# Additional note: We should probably completely hide envs from public methods.


# INCREDIBLY STUPID IMPLEMENTATION
# PLEASE DON'T THINK I'M STUPID
# (I USUALLY DON'T THINK I'M STUPID)
class Spread
  constructor: (@pairs) ->
    # NOTE: @pairs is an array of [env, value] arrays
    #   (and an env is a Map from origins to indices)

  # Assuming this is a spread of spreads of Xs, turns it into a spread of Xs
  # NOTE: for now, we assert that the origins of the top-level spread are
  # different than the origins in the lower-level-spreads
  join: () ->
    valuesToReturn = []
    for [env1, value1] in @pairs
      # We assume value1 is a spread
      for [env2, value2] in value1.pairs
        valuesToReturn.push([_.extend({}, env1, env2), value2])
    return new Spread(valuesToReturn)

  # If this is a spread of arrays, and otherSpread is a spread of arrays, and
  # then this produces Monadic.Spread.multimap([this, otherSpread], func).
  _multimap2: (otherSpread, func) ->
    valuesToReturn = []
    for [env1, value1] in @pairs
      for [env2, value2] in otherSpread.pairs
        if mapsAgree(env1, env2)
          valuesToReturn.push([_.extend({}, env1, env2), func(value1, value2)])
    return new Spread(valuesToReturn)

  map: (func) ->
    return new Spread(@pairs.map(([env, value]) -> [env, func(value, env)]))

  items: ->
    return _.pluck(@pairs, 1)


  # CONSTRUCTORS

  @fromArray: (items, returnNewOrigin = false) ->
    newOrigin = Util.generateId()
    values = items.map (item, index) -> [_.object([[newOrigin, index]]), item]
    spread = new Spread(values)
    return if returnNewOrigin then [spread, newOrigin] else spread

  @fromValue: (value) ->
    return new Spread([[{}, value]])



  # OPERATORS

  toArray: ->
    # Throw out envs
    _.pluck(@pairs, 1)

  @product: (spreads) ->
    concat = (arraySoFar, nextValue) -> arraySoFar.concat([nextValue])
    reducer = (spreadSoFar, nextSpread) -> spreadSoFar._multimap2(nextSpread, concat)
    spreads.reduce(reducer, Spread.fromValue([]))

  @productObject: (spreadObject) ->
    addValue = (nextKey) -> (objectSoFar, nextValue) -> _.extend(_.object([[nextKey, nextValue]]), objectSoFar)
    reducer = (spreadSoFar, [nextKey, nextSpread]) -> spreadSoFar._multimap2(nextSpread, addValue(nextKey))
    _.pairs(spreadObject).reduce(reducer, Spread.fromValue({}))

  @multimap: (args, func) ->
    if _.isArray(args)
      Spread.product(args).map((tuple, spreadEnv) -> func.apply(null, tuple.concat([spreadEnv])))
    else if _.isObject(args)
      Spread.productObject(args).map(func)
    else
      raise new Error

  @multibind: (args, func) ->
    Spread.multimap(args, func).join()

  @flexibind: (args, func) ->
    # Flexible in two ways:
    #   If some arguments are not spreads, they will automatically be wrapped in one.
    #   If the output of the function is a spread, multibind will be used;
    #     otherwise, multimap.
    #   (With this set-up, it's more-or-less impossible to end up with a spread of spreads.)

    if _.isArray(args)
      args = args.map (arg) -> if arg instanceof Spread then arg else Spread.fromValue(arg)
      result = Spread.multimap(args, func)
    else if _.isObject(args)
      args = _.mapObject args, (arg) -> if arg instanceof Spread then arg else Spread.fromValue(arg)
      result = Spread.multimap(args, func)
    else
      raise new Error

    if result.pairs.length and result.pairs[0][1] instanceof Spread
      return result.join()
    else
      return result

  _applyEnv: (someEnv) ->
    matchingPairs = @pairs.filter ([env, value]) -> mapsAgree(env, someEnv)
    return new Spread(matchingPairs.map ([env, value]) -> [_.omit(env, _.keys(someEnv)), value])

  # Gets the "default" member of a spread: has all indices set to 0
  default: ->
    if @pairs.length == 0
      throw "default called, but spread is empty!"
    else
      return _.find(@pairs, ([env, value]) -> _.every(_.values(env), (index) -> index == 0))[1]



  # This method only applies to tree-spreads. A tree-spread is a spread of
  # tree-spread-nodes. A tree-spread-node must have a method "children", which
  # must return an array of tree-spreads. A tree-spread-node must also have a
  # method "setChildren", which should return a new version of itself with new
  # children. (The tree-spread-node may store additional data beyond its
  # children; in this case, it should use setChildren as an opportunity to clone
  # that data.)
  _applyEnvToTree: (someEnv) ->
    return @_applyEnv(someEnv).map((node) ->
      node.setChildren(node.children().map((spreadUnderNode) ->
        spreadUnderNode._applyEnvToTree(someEnv))))

  # Here, otherSpread should be a tree-spread.
  multimap2WithTree: (otherSpread, func) ->
    return @map((value, env) -> func(value, otherSpread._applyEnvToTree(env), env))

  # Here, otherSpreads should be an array of tree-spreads.
  multimap2WithTrees: (otherSpreads, func) ->
    return @map((value, env) -> func(value, _.invoke(otherSpreads, "_applyEnvToTree", env), env))

mapsAgree = (map1, map2) ->
  _.pairs(map1).every ([key, value]) -> !_.has(map2, key) or map2[key] == value


module.exports = Monadic = {Spread}
