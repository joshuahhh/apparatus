_ = require "underscore"
NewSystem = require "./NewSystem"


module.exports = (BuiltinEnvironment) ->
  # Root "Node" of the Apparatus object model:

  # IDEA: This should be the only bundle which refers to @node. All other bundles
  # should only indirectly refer to @node, through calls to methods defined here.

  # OTHER IDEA: This bundle can assume that @node is up-to-date, with all
  # NewSystem redundancies computed. (The idea is that these recomputations will
  # only need to happen when NewSystem changes are occurring, and bundle code
  # will happen in-between these changes, so we can just compute redundancies
  # after each change.)

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Node", undefined,
    {
      label: "Node"

      linkTargetBundles: ->
        _.mapObject @node.linkTargetNodes(), (node) -> node.bundle

      parent: ->
        @node.tree.getNodeById(this.parentId)

      childBundlesOfType: (predicate) ->
        # UGH: this is gonna get mad tiresome
        _.pluck @node.childNodesOfType(predicate), "bundle"

      depth: ->
        # TODO
        0
    }

  BuiltinEnvironment.createVariantOfBuiltinSymbol "NodeWithAttributes", "Node",
    {
      label: "Node With Attributes"

      attributes: ->
        @childBundlesOfType("isAttribute")

      getAttributesByName: ->
        _.indexBy @attributes(), "name"

      getAttributesValuesByName: ->
        _.mapObject @getAttributesByName(), (attr) -> attr.value()
    }
