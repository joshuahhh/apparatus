Dataflow = require "../Dataflow/Dataflow"


module.exports = class ParticularElement
  constructor: (@element, @spreadEnv) ->
    @spreadEnv ?= Dataflow.SpreadEnv.empty

  isEqualTo: (particularElement) ->
    return @element == particularElement.element and
      @spreadEnv.isEqualTo(particularElement.spreadEnv)

  isAncestorOf: (particularElement) ->
    return @element.isAncestorOf(particularElement.element) and
      @spreadEnv.contains(particularElement.spreadEnv)

  accumulatedMatrix: ->
    accumulatedMatrix = @element.accumulatedMatrixAsSpread()
    accumulatedMatrix = @spreadEnv.resolveWithDefault(accumulatedMatrix)
    return accumulatedMatrix

  contextMatrix: ->
    contextMatrix = @element.contextMatrixAsSpread()
    contextMatrix = @spreadEnv.resolveWithDefault(contextMatrix)
    return contextMatrix
