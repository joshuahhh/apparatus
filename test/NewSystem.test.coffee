_ = require("underscore")
test = require("tape")

NewSystem = require("../src/NewSystem/NewSystem")


test "getNodeById works", (t) ->
  tree = new NewSystem.Tree(
    [
      node_a = new NewSystem.TreeNode("a"),
      node_b = new NewSystem.TreeNode("b"),
    ]
  )
  t.equal(tree.getNodeById("a"), node_a)
  t.end()


test "Change_AddNode basically works", (t) ->
  tree = new NewSystem.Tree([new NewSystem.TreeNode("a")])
  change = new NewSystem.Change_AddNode("b")
  change.apply(tree, null)  # no environment needed
  t.deepEqual(tree.nodes.map((node) => node.id), ["a", "b"])
  t.end()


test "Change_AddChild basically works", (t) ->
  tree = new NewSystem.Tree([
    node_a = new NewSystem.TreeNode("a"),
    node_b = new NewSystem.TreeNode("b"),
  ])
  change = new NewSystem.Change_AddChild(
    "a",
    "b",
    Infinity
  )
  change.apply(tree, null)  # no environment needed
  t.deepEqual(node_a.childIds, ["b"])
  t.end()


test "Change_CloneSymbol basically works", (t) ->
  environment = new NewSystem.Environment({
    mySymbol: new NewSystem.Symbol(
      new NewSystem.ChangeList([
        new NewSystem.Change_AddNode("a"),
        new NewSystem.Change_AddNode("b"),
        new NewSystem.Change_AddChild(
          "a",
          "b",
          Infinity
        ),
      ])
    )
  })
  tree = new NewSystem.Tree([node_a = new NewSystem.TreeNode("a")])
  change = new NewSystem.Change_CloneSymbol("mySymbol", "myCloneId")
  change.apply(tree, environment)
  t.deepEqual(tree.nodes.map((node) => node.id), ["a", "myCloneId/a", "myCloneId/b"], "We have the right nodeIds")
  t.deepEqual(tree.getNodeById("myCloneId/a").childIds, ["myCloneId/b"], "Child relationships are preserved")
  t.end()


test "'Group' integration test", (t) ->
  environment = new NewSystem.Environment
    Node: new NewSystem.Symbol(
      new NewSystem.ChangeList([
        new NewSystem.Change_AddNode("root"),
      ])
    )
    Transform: new NewSystem.Symbol(
      new NewSystem.ChangeList([
        new NewSystem.Change_CloneSymbol("Node", "")
      ])
    )
    Group: new NewSystem.Symbol(
      new NewSystem.ChangeList([
        new NewSystem.Change_AddNode("groupNode"),
        new NewSystem.Change_CloneSymbol("Transform", "transform"),
        new NewSystem.Change_AddChild(
          "groupNode",
          "transform/root",
          Infinity
        ),
      ])
    )
  tree = new NewSystem.Tree()
  change = new NewSystem.Change_CloneSymbol("Group", "group1")
  change.apply(tree, environment)
  t.deepEqual(
    tree.nodes.map((node) -> _.pick(node, "id", "childIds")),
    [
      id: "group1/groupNode"
      childIds: ["group1/transform/root"]
    ,
      id: "group1/transform/root"
      childIds: []
    ]
  )
  t.end()


# TODO: Test that constructing trees, merging in new trees, adding nodes,
# setting pointers, etc. all set nodes/pointers to have the right .tree
# reference! Or just get rid of that fucking reference already.
