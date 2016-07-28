Dataflow = require "../Dataflow/Dataflow"


module.exports = class ParticularElement
  constructor: (@elementId, @spreadEnv) ->
    @spreadEnv ?= Dataflow.SpreadEnv.empty

  element: (tree) ->
    return tree.getNodeById(@elementId).bundle

  isEqualTo: (particularElement) ->
    return @elementId == particularElement.elementId and
      @spreadEnv.isEqualTo(particularElement.spreadEnv)

  isAncestorOf: (particularElement, tree) ->
    element = tree.getNodeById(@elementId).bundle
    otherElement = tree.getNodeById(particularElement.elementId).bundle
    return element.isAncestorOf(otherElement) and
      @spreadEnv.contains(particularElement.spreadEnv)

  accumulatedMatrix: (tree) ->
    element = tree.getNodeById(@elementId).bundle
    accumulatedMatrix = element.accumulatedMatrix.asSpread()
    accumulatedMatrix = @spreadEnv.resolveWithDefault(accumulatedMatrix)
    return accumulatedMatrix

  contextMatrix: (tree) ->
    element = tree.getNodeById(@elementId).bundle
    contextMatrix = element.contextMatrix.asSpread()
    contextMatrix = @spreadEnv.resolveWithDefault(contextMatrix)
    return contextMatrix
