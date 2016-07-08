_ = require "underscore"


module.exports = NewSystem = {}

# These are dynamic.

class NewSystem.Tree
  constructor: (@nodes={}, @rootNode) ->

  addNode: (nodeId, node) ->
    @nodes[nodeId] = node

  setRootNode: (node) ->
    @rootNode = node

  mergeTree: (tree) ->
    for id, node of tree.nodes
      @addNode(id, node)

  recomputeRedundancies: ->
    # Assign IDs
    for nodeId, node of @nodes
      node.id = nodeId

    # Clear parents
    for nodeId, node of @nodes
      node.parent = undefined

    # Assign parents
    for nodeId, node of @nodes
      for childNode in node.children
        childNode.parent = node

  makeClone: (cloneId) ->
    newNodes = _.object(_.map(@nodes, (node, id) => [cloneId + '/' + id, node]))
    return new NewSystem.Tree(newNodes, @rootNode)


# TreeNodes shouldn't know anything about IDs (except their own, calculated by
# Tree::recomputeRedundancies, used for editing). Relationships should be stored
# as direct references.
class NewSystem.TreeNode
  constructor: () ->
    @children = []

  removeChild: (child) ->
    removalIndex = @children.indexOf(child)
    if removalIndex == -1
      throw "Cannot remove a child that doesn't exist"
    @children.splice(removalIndex, 1)

  deparent: () ->
    @parent.removeChild(child) if @parent

  addChild: (child, insertionIndex) ->
    child.deparent()
    @children.splice(insertionIndex, 0, child)


# A "Change" is a description of a change which can be performed to a tree. It
# stores ID references to relevant nodes & clones in a special place, so that
# they can be appropriately prefixed if you want to run a change in a context.
# Changes are a static, syntactic sort of thing, except for the "apply" method.

# DESIGN NOTE: The more high-level Changes are, the more robust they can be. For
# instance, take the process of moving a node to a new parent. For simplicity,
# you might want to encode this as two Changes: 1. Remove from parent X. 2. Add
# to parent Y. However, if "the past changes" (because some cloned symbol
# changes) and the node no longer has X as a parent, things will break! It is
# better to have a single change which performs both the removal from the
# (unknown) previous parent and the addition to the new tree. This means that
# changes will have to do more "looking around" in the tree.

# DESIGN QUESTION: Should deleting a node remove it and all of its children from
# the tree, or just de-parent it? What happens if, post-cloning, some descendent
# node is moved outside the deleted node?

class NewSystem.Change
  constructor: (@ids={}) ->

  prefix: (prefix) ->
    Object.create(this, {references: _.mapObject(@references, )})

  apply: (tree, environment) ->
    throw ["Not implemented!", this]

class NewSystem.ChangeEnvironment
  constructor: (@symbols={}, @mixins={}) ->
    # For now, @symbols maps symbolId => ChangeList

  getTreeForSymbol: (symbolId) ->
    symbol = @symbols[symbolId]
    tree = new NewSystem.Tree()
    symbol.apply(tree, this)
    return tree

class NewSystem.Change_SetRootNode extends NewSystem.Change
  constructor: (rootNode) ->
    super({rootNode})

  apply: (tree, environment) ->
    # Can't fail!
    tree.addNode(@ids.newNodeId, new NewSystem.TreeNode())

class NewSystem.Change_AddNode extends NewSystem.Change
  constructor: (newNodeId) ->
    super({newNodeId})

  apply: (tree, environment) ->
    # Can't fail!
    tree.addNode(@ids.newNodeId, new NewSystem.TreeNode())

class NewSystem.Change_CloneSymbol extends NewSystem.Change
  constructor: (@symbolId, newCloneId) ->
    super({newCloneId})

  apply: (tree, environment) ->
    # Fails if symbol doesn't exist
    symbolTree = environment.getTreeForSymbol(@symbolId)
    clonedTree = symbolTree.makeClone(@ids.newCloneId)
    tree.mergeTree(clonedTree)

class NewSystem.Change_AddChild extends NewSystem.Change
  constructor: (parentId, childId, @insertionIndex) ->
    super({childId, parentId})

  apply: (tree, environment) ->
    # Fails if either parent or child doesn't exist
    parent = tree.nodes[@ids.parentId]
    child = tree.nodes[@ids.childId]
    console.log(parent, child)
    parent.addChild(child, @insertionindex)

class NewSystem.Change_DeparentNode extends NewSystem.Change
  constructor: (childId) ->
    super({childId})

  apply: (tree, environment) ->
    # Fails if child doesn't exist
    node = tree.nodes[@ids.childId]
    node.deparent()

class NewSystem.Change_DeparentNode extends NewSystem.Change
  constructor: (childId) ->
    super({childId})

  apply: (tree, environment) ->
    # Fails if child doesn't exist
    node = tree.nodes[@ids.childId]
    node.deparent()


class NewSystem.Change_ExtendNode extends NewSystem.Change
  constructor: (nodeId, @mixinId) ->
    super({nodeId})

  apply: (tree, environment) ->
    # Fails if node doesn't exist or mixin doesn't exist
    node = tree.nodes[@ids.nodeId]
    node.extend()


class NewSystem.ChangeList
  constructor: (@changes) ->

  apply: (tree, environment) ->
    for change in @changes
      console.log('applying', change)
      tree.recomputeRedundancies()
      change.apply(tree, environment)
    tree.recomputeRedundancies()


# Given a built-in symbol-id and a
NewSystem.createVariant = ()

NewSystem.Test_ChangeEnvironment = new NewSystem.ChangeEnvironment(
  [
    Group: new NewSystem.ChangeList [
      new NewSystem.Change_AddNode('groupNode'),
      new NewSystem.Change_CloneSymbol('Transform', 'transform'),
      new NewSystem.Change_AddChild('groupNode', 'transform/transformNode', 0),
    ]
    Transform: new NewSystem.ChangeList [
      new NewSystem.Change_AddNode('transformNode'),
    ]
  ],
  [

  ]
)
