Dataflow = require "../Dataflow/Dataflow"


# A ParticularElement is an Element together with a spread environment to
# specify what the index values are for its Element's spreads.
module.exports = class ParticularElement
  constructor: (@element, @accumulatedMatrix, @contextMatrix, @spreadEnv) ->
    @spreadEnv ?= Dataflow.SpreadEnv.empty

  # isEqualTo: (particularElement) ->
  #   return @element == particularElement.element and
  #     @spreadEnv.isEqualTo(particularElement.spreadEnv)

  # This is probably used!
  isAncestorOf: (particularElement) ->
    return @element.isAncestorOf(particularElement.element) and
      @spreadEnv.contains(particularElement.spreadEnv)
