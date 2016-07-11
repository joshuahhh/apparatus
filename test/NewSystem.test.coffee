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
