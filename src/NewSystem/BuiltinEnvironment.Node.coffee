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

      parentBundle: ->
        @node.tree.getNodeById(@node.parentId, true)?.bundle

      childBundlesOfType: (predicate) ->
        # UGH: this is gonna get mad tiresome
        _.pluck @node.childNodesOfType(predicate), "bundle"

      depth: ->
        # TODO
        0

      isAncestorOf: (grandChild) ->
        if this == grandChild
          return true
        if parent = grandChild.parentBundle()
          return @isAncestorOf(parent)
        return false
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



  # Basic (atomic) changes:

  BuiltinEnvironment.addAtomicChangeType "AddNode", ({nodeId}, tree, environment) ->
    tree.addNode(new NewSystem.TreeNode(nodeId))

  BuiltinEnvironment.addAtomicChangeType "CloneSymbol", ({symbolId, cloneId}, tree, environment) ->
    # An empty-string cloneId stands for cloning-as-master
    if not _.isString(cloneId)
      console.log {symbolId, cloneId}
      throw "CloneSymbol needs a string-valued cloneId, not #{cloneId}!"

    # Fails if symbol doesn't exist
    symbolTree = environment.getTreeForSymbol(symbolId)
    clonedTree = symbolTree.makeClone(symbolId, cloneId)
    tree.mergeTree(clonedTree)

  # PARENTS AND CHILDREN

  BuiltinEnvironment.addAtomicChangeType "AddChild", ({parentId, childId, insertionIndex}, tree, environment) ->
    if not _.isNumber(insertionIndex)
      throw "AddChild needs a numeric insertionIndex! (Can be `Infinity`.)"

    # Fails if either parent or child doesn't exist
    tree.addChildToNode(parentId, childId, insertionIndex)

  BuiltinEnvironment.addCompoundChangeType "AddChildFromClonedSymbol", ({parentId, insertionIndex, symbolId, cloneId}) ->
    [
      {type: "CloneSymbol", symbolId, cloneId}
      {type: "AddChild", parentId, childId: NewSystem.buildId(cloneId, "root"), insertionIndex}
    ]

  BuiltinEnvironment.addAtomicChangeType "DeparentNode", ({nodeId}, tree, environment) ->
    # Fails if child doesn't exist
    tree.deparentNode(nodeId)

  # LINKS

  BuiltinEnvironment.addAtomicChangeType "SetNodeLinkTarget", ({nodeId, linkKey, targetId}, tree, environment) ->
    # Fails if node or target don't exist
    tree.getNodeById(nodeId).setLinkTarget(linkKey, targetId)

  BuiltinEnvironment.addAtomicChangeType "RemoveNodeLink", ({nodeId, linkKey}, tree, environment) ->
    # Fails if node doesn't exist
    tree.getNodeById(nodeId).setLinkTarget(linkKey, undefined)

  BuiltinEnvironment.addAtomicChangeType "RemoveAllLinks", ({nodeId}, tree, environment) ->
    # Fails if node doesn't exist
    tree.getNodeById(nodeId).removeAllLinks()

  # IN THE BUNDLE

  BuiltinEnvironment.addAtomicChangeType "ExtendNodeWithMixin", ({nodeId, mixinId}, tree, environment) ->
    # Fails if node doesn't exist or mixin doesn't exist
    tree.getNodeById(nodeId).extendBundle(environment.getMixinById(mixinId))

  BuiltinEnvironment.addAtomicChangeType "ExtendNodeWithLiteral", ({nodeId, literal}, tree, environment) ->
    tree.getNodeById(nodeId).extendBundle(literal)
    #
    # propValueToString: (propName, propValue) ->
    #   if propName == "literal"
    #     return JSON.stringify(propValue)
    #   else
    #     return propValue.toString()

  BuiltinEnvironment.addAtomicChangeType "RunConstructor", ({nodeId, methodName, methodArguments}, tree, environment) ->
    # Fails if node or method don't exist
    tree.getNodeById(nodeId).runConstructorAndRemember(methodName, methodArguments)

  BuiltinEnvironment.addAtomicChangeType "Log", ({}, tree, environment) ->
    console.log tree
