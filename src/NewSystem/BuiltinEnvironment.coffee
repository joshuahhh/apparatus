_ = require "underscore"
NewSystem = require "./NewSystem"


module.exports = BuiltinEnvironment = new NewSystem.Environment()

# IDEA: Compiled tree goes through one ADDITIONAL step, to produce a tree
# structure which is totally separated from the whole change-log system (and
# which is possibly 100% compatible with existing Apparatus rendering code.)

# (Why? Currently, compiled trees are designed to fit into the change-log
# system. They're designed to be easy to clone, and they have pointers and stuff
# like that. These needs are separate from the needs of Apparatus rendering.)

# PROBLEM: If you're continuously changing an attribute value, it would suck if
# every tiny change required a full re-copy of the entire diagram. ALSO this
# would, like, invalidate attribute values (in a future validation-based
# attribute system), unless you're really careful and stuff.



# Root "Node" of the Apparatus object model:

# IDEA: This should be the only bundle which refers to @node. All other bundles
# should only indirectly refer to @node, through calls to methods defined here.

BuiltinEnvironment.createVariantOfBuiltinSymbol "Node", undefined,
  {
    label: "Node"

    linkTargetBundles: ->
      _.mapObject @node.linkTargetNodes(), (node) -> node.bundle
  }

BuiltinEnvironment.createVariantOfBuiltinSymbol "NodeWithAttributes", "Node",
  {
    label: "Node With Attributes"

    attributes: ->
      @childNodesOfType("isAttribute")

    getAttributesByName: ->
      _.indexBy @attributes(), "name"

    getAttributesValuesByName: ->
      _.mapObject @getAttributesByName(), (attr) -> attr.value()
  }

BuiltinEnvironment.changes_CloneSymbolAndAddToRoot = (symbolId, cloneId) ->
  [
    new NewSystem.Change_CloneSymbol(symbolId, cloneId)
    new NewSystem.Change_AddChild(
      new NewSystem.NodeRef_Pointer("root"),
      new NewSystem.NodeRef_Pointer(cloneId + "/root"),
      Infinity)
  ]

(require "./BuiltinEnvironment.Attribute")(BuiltinEnvironment)

(require "./BuiltinEnvironment.Component")(BuiltinEnvironment)

(require "./BuiltinEnvironment.Element")(BuiltinEnvironment)
