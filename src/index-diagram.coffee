_ = require "underscore"
R = require "./View/R"

NewSystem = require "./NewSystem/NewSystem"
BuiltinEnvironment = require "./NewSystem/BuiltinEnvironment"
require "./NewSystem/TreeDiagram"

window.NewSystem = NewSystem

tree = new NewSystem.Tree()
changeList = new NewSystem.ChangeList([
  new NewSystem.Change_CloneSymbol("Group", "myGroup")
  new NewSystem.Change_CloneSymbol("Rectangle", "myRectangle")
  new NewSystem.Change_AddChild(
    new NewSystem.NodeRef_Pointer("myGroup/root"),
    new NewSystem.NodeRef_Pointer("myRectangle/root"),
    Infinity)
  # BuiltinEnvironment.changes_SetAttributeExpression(
  #   # it's really interesting that this id path sucks so much...
  #   new NewSystem.NodeRef_Pointer("group/master/transform/x/root"),
  #   "ref1 * 2 + ref2",
  #   {
  #     ref1: new NewSystem.NodeRef_Pointer("group/master/transform/y/root")
  #     # ref2: new NewSystem.NodeRef_Pointer("group2/master/transform/y/root")
  #   })...
])

changeList.apply(tree, BuiltinEnvironment)

console.log(tree)

R.render(
  R.div {style: {marginTop: 20, marginLeft: 20}},
    R.TreeDiagram {tree}
  document.getElementById("apparatus-container")
)
