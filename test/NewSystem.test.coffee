test = require("tape")

NewSystem = require("../src/NewSystem/NewSystem")


test "NodeRef_Node resolves correctly", (t) ->
  tree = new NewSystem.Tree(
    [
      node_a = new NewSystem.TreeNode('a'),
      node_b = new NewSystem.TreeNode('b'),
    ],
    [
      pointer_a = new NewSystem.TreePointer('a', 'b')
    ]
  )
  ref = new NewSystem.NodeRef_Node('a')
  t.equal(ref.resolve(tree), node_a)
  t.end()

test "NodeRef_Pointer resolves correctly", (t) ->
  tree = new NewSystem.Tree(
    [
      node_a = new NewSystem.TreeNode('a'),
      node_b = new NewSystem.TreeNode('b'),
    ],
    [
      pointer_a = new NewSystem.TreePointer('a', 'b')
    ]
  )
  ref = new NewSystem.NodeRef_Pointer('a')
  t.equal(ref.resolve(tree), node_b)
  t.end()

test "Change_AddNode basically works", (t) ->
  tree = new NewSystem.Tree([new NewSystem.TreeNode('a')])
  change = new NewSystem.Change_AddNode('b')
  change.apply(tree, null)  # no environment needed
  t.deepEqual(tree.nodes.map((node) => node.id), ['a', 'b'])
  t.end()

test "Change_SetPointerDestination basically works", (t) ->
  tree = new NewSystem.Tree([node_a = new NewSystem.TreeNode('a')])
  change = new NewSystem.Change_SetPointerDestination('b', new NewSystem.NodeRef_Node('a'))
  change.apply(tree, null)  # no environment needed
  ref = new NewSystem.NodeRef_Pointer('b')
  t.equal(ref.resolve(tree), node_a)
  t.end()

test "Change_AddChild basically works", (t) ->
  tree = new NewSystem.Tree([
    node_a = new NewSystem.TreeNode('a'),
    node_b = new NewSystem.TreeNode('b'),
  ])
  change = new NewSystem.Change_AddChild(
    new NewSystem.NodeRef_Node('a'),
    new NewSystem.NodeRef_Node('b'),
    Infinity
  )
  change.apply(tree, null)  # no environment needed
  t.deepEqual(node_a.childIds, ['b'])
  t.end()


test "Change_CloneSymbol basically works", (t) ->
  environment = new NewSystem.Environment({
    mySymbol: new NewSystem.Symbol(
      new NewSystem.ChangeList([
        new NewSystem.Change_AddNode('a'),
        new NewSystem.Change_AddNode('b'),
        new NewSystem.Change_AddChild(
          new NewSystem.NodeRef_Node('a'),
          new NewSystem.NodeRef_Node('b'),
          Infinity
        ),
      ])
    )
  })
  tree = new NewSystem.Tree([node_a = new NewSystem.TreeNode('a')])
  change = new NewSystem.Change_CloneSymbol('mySymbol', 'myCloneId')
  change.apply(tree, environment)
  t.deepEqual(tree.nodes.map((node) => node.id), ['a', 'myCloneId/a', 'myCloneId/b'], 'We have the right nodeIds')
  t.deepEqual(tree.getNodeById('myCloneId/a').childIds, ['myCloneId/b'], 'Child relationships are preserved')
  t.end()


test "GroupInGroup integration test", (t) ->
  environment = new NewSystem.Environment
    Transform: new NewSystem.Symbol(
      new NewSystem.ChangeList([
        new NewSystem.Change_AddNode("transformNode"),
        new NewSystem.Change_SetPointerDestination("root", new NewSystem.NodeRef_Node("transformNode")),
      ])
    )
    Group: new NewSystem.Symbol(
      new NewSystem.ChangeList([
        new NewSystem.Change_AddNode("groupNode"),
        new NewSystem.Change_SetPointerDestination("root", new NewSystem.NodeRef_Node("groupNode")),
        new NewSystem.Change_CloneSymbol("Transform", "transform"),
        new NewSystem.Change_AddChild(
          new NewSystem.NodeRef_Node("groupNode"),
          new NewSystem.NodeRef_Pointer("transform/root"),
          Infinity
        ),
      ])
    )
  tree = new NewSystem.Tree()
  change = new NewSystem.Change_CloneSymbol("Group", "group1")
  change.apply(tree, environment)
  tree.stripRedundancies()
  t.deepEqual tree,
    new NewSystem.Tree(
      [
        new NewSystem.TreeNode("group1/groupNode", ["group1/transform/transformNode"], {}),
        new NewSystem.TreeNode("group1/transform/transformNode", [], {}),
      ],
      [
        new NewSystem.TreePointer("group1/root", "group1/groupNode"),
        new NewSystem.TreePointer("group1/transform/root", "group1/transform/transformNode"),
      ]
    )
  t.end()


# TODO: Test that constructing trees, merging in new trees, adding nodes,
# setting pointers, etc. all set nodes/pointers to have the right .tree
# reference! Or just get rid of that fucking reference already.
