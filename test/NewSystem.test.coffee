_ = require("underscore")
test = require("tape")

NewSystem = require("../src/NewSystem/NewSystem")
# TODO: Should these basic changes be put someplace outside BuiltinEnvironment?
BuiltinEnvironment = require("../src/NewSystem/BuiltinEnvironment")


test "getNodeById works", (t) ->
  tree = new NewSystem.Tree(
    [
      node_a = new NewSystem.TreeNode("a"),
      node_b = new NewSystem.TreeNode("b"),
    ]
  )
  t.equal(tree.getNodeById("a"), node_a)
  t.end()


test "AddNode basically works", (t) ->
  tree = new NewSystem.Tree([new NewSystem.TreeNode("a")])
  change = {type: "AddNode", nodeId: "b"}
  BuiltinEnvironment.resolveChange(change).apply(tree, null)  # no environment needed
  t.deepEqual(tree.nodes.map((node) => node.id), ["a", "b"])
  t.end()


test "AddChild basically works", (t) ->
  tree = new NewSystem.Tree([
    node_a = new NewSystem.TreeNode("a"),
    node_b = new NewSystem.TreeNode("b"),
  ])
  change = {type: "AddChild", parentId: "a", childId: "b", insertionIndex: Infinity}
  BuiltinEnvironment.resolveChange(change).apply(tree, null)  # no environment needed
  t.deepEqual(node_a.childIds, ["b"])
  t.end()


test "CloneSymbol basically works", (t) ->
  environment = new NewSystem.CompoundEnvironment([
    BuiltinEnvironment
    new NewSystem.Environment
      mySymbol: new NewSystem.Symbol(
        new NewSystem.ChangeList([
          {type: "AddNode", nodeId: "a"}
          {type: "AddNode", nodeId: "b"}
          {type: "AddChild", parentId: "a", childId: "b", insertionIndex: Infinity}
        ])
      )
  ])
  tree = new NewSystem.Tree([node_a = new NewSystem.TreeNode("a")])
  change = {type: "CloneSymbol", symbolId: "mySymbol", cloneId: "myCloneId"}
  environment.resolveChange(change).apply(tree, environment)
  t.deepEqual(tree.nodes.map((node) => node.id), ["a", "myCloneId/a", "myCloneId/b"], "We have the right nodeIds")
  t.deepEqual(tree.getNodeById("myCloneId/a").childIds, ["myCloneId/b"], "Child relationships are preserved")
  t.end()


test "'MyGroup' integration test", (t) ->
  environment = new NewSystem.CompoundEnvironment [
    BuiltinEnvironment
    new NewSystem.Environment
      MyNode: new NewSystem.Symbol(
        new NewSystem.ChangeList [
          {type: "AddNode", nodeId: "root"}
        ]
      )
      MyTransform: new NewSystem.Symbol(
        new NewSystem.ChangeList [
          {type: "CloneSymbol", symbolId: "MyNode", cloneId: ""}
        ]
      )
      MyGroup: new NewSystem.Symbol(
        new NewSystem.ChangeList [
          {type: "CloneSymbol", symbolId: "MyNode", cloneId: ""}
          {type: "CloneSymbol", symbolId: "MyTransform", cloneId: "transform"}
          {type: "AddChild", parentId: "root", childId: "transform/root", insertionIndex: Infinity}
        ]
      )
  ]
  tree = new NewSystem.Tree()
  change = {type: "CloneSymbol", symbolId: "MyGroup", cloneId: ""}
  BuiltinEnvironment.resolveChange(change).apply(tree, environment)
  t.deepEqual(
    tree.nodes.map((node) -> _.pick(node, "id", "childIds")),
    [
      id: "root"
      childIds: ["transform/root"]
    ,
      id: "transform/root"
      childIds: []
    ]
  )
  t.end()


# TODO: Test that constructing trees, merging in new trees, adding nodes,
# setting pointers, etc. all set nodes/pointers to have the right .tree
# reference! Or just get rid of that fucking reference already.
