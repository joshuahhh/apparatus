_ = require "underscore"
R = require "./View/R"

NewSystem = require "./NewSystem/NewSystem"
BuiltinEnvironment = require "./NewSystem/BuiltinEnvironment"
require "./NewSystem/TreeDiagram"


tree = new NewSystem.Tree(
  [
    new NewSystem.TreeNode(
      'group1/groupNode'
      [ 'group1/transform/transformNode' ],
      {}
    ),
    new NewSystem.TreeNode(
      'group1/transform/transformNode',
      [],
      {}
    ),
    new NewSystem.TreeNode(
      'group1/transform/otherTransformNode',
      [],
      {}
    ),
  ]
  [
    new NewSystem.TreePointer(
      'group1/root',
      'group1/groupNode'
    ),
    new NewSystem.TreePointer(
      'group1/transform/root',
      'group1/transform/transformNode',
    ),
  ]
)

# tree = new NewSystem.Tree()
#
# (new NewSystem.Change_CloneSymbol("Group", "myElement")).apply(tree, BuiltinEnvironment)


R.render(
  R.div {style: {marginTop: 20, marginLeft: 20}},
    R.TreeDiagram {tree}
  document.getElementById("apparatus-container")
)
