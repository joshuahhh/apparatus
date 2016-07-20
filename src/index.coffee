_ = require "underscore"
R = require "./View/R"

NewSystem = require "./NewSystem/NewSystem"
BuiltinEnvironment = require "./NewSystem/BuiltinEnvironment"
require "./NewSystem/TreeDiagram"


# tree = new NewSystem.Tree(
#   [
#     new NewSystem.TreeNode(
#       'group1/groupNode'
#       [
#         'group1/transform1/transformNode1'
#         'newNode'
#         'group1/transform2/transformNode2'
#       ],
#       {}
#     ),
#     new NewSystem.TreeNode(
#       'group1/transform1/transformNode1',
#       [],
#       {}
#     ),
#     new NewSystem.TreeNode(
#       'newNode',
#       [],
#       {}
#     ),
#     new NewSystem.TreeNode(
#       'group1/transform2/transformNode2',
#       [],
#       {}
#     ),
#   ]
# )

tree = new NewSystem.Tree()
changeList = new NewSystem.ChangeList([
  new NewSystem.Change_CloneSymbol("Group", "group1")
  new NewSystem.Change_CloneSymbol("Group", "group2")
  new NewSystem.Change_AddChild(
    new NewSystem.NodeRef_Pointer("group1/root"),
    new NewSystem.NodeRef_Pointer("group2/root"),
    Infinity)])

changeList.apply(tree, BuiltinEnvironment)

console.log(tree)

R.render(
  R.div {style: {marginTop: 20, marginLeft: 20}},
    R.TreeDiagram {tree}
  document.getElementById("apparatus-container")
)
