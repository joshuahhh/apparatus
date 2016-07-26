_ = require "underscore"
NewSystem = require "./NewSystem"


module.exports = BuiltinEnvironment = new NewSystem.Environment()
global.BuiltinEnvironment = BuiltinEnvironment  # TODO: temp

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

# CURRENT SOLUTION: Bundles! I guess?


BuiltinEnvironment.addCompoundChangeType "CloneSymbolAndAddToParent", ({parentId, symbolId, cloneId}) ->
  [
    {type: "CloneSymbol", symbolId: symbolId, cloneId: cloneId}
    {type: "AddChild", parentId: parentId, childId: NewSystem.buildId(cloneId, "root"), insertionIndex: Infinity}
  ]

(require "./BuiltinEnvironment.Node")(BuiltinEnvironment)

(require "./BuiltinEnvironment.Attribute")(BuiltinEnvironment)

(require "./BuiltinEnvironment.Component")(BuiltinEnvironment)

(require "./BuiltinEnvironment.Element")(BuiltinEnvironment)
