_ = require "underscore"


module.exports = NewSystem = {}

# NOTES:

# 1. For now, we are eliminating the idea of running a change in a tree in any
# but the root context. You should build up trees for cloned symbols first, and
# then clone them into the tree whole.

# 2. Don't ever have links directly between nodes, while you're still running
# changes on the tree. Why? It makes cloning really hard! Just use IDs, and then
# you'll be fine.

# 2.1. What happens when you clone a tree with mixed-in properties? OH WOW maybe
# we can just use prototypes here? We'll have to be perpetually careful about,
# e.g., "do you really have a parent listed yet?" The alternative is just to
# copy over properties. (That would be easiest if we had mixed-in properties
# stored in a special property object.)

buildId = (cloneId, id) -> cloneId + "/" + id

class NewSystem.Tree
  constructor: (@nodes=[], @pointers=[]) ->
    @nodesById = _.indexBy(@nodes, "id")
    @pointersById = _.indexBy(@pointers, "id")

  getNodeById: (nodeId) ->
    @nodesById[nodeId]

  getPointerById: (pointerId) ->
    @pointersById[pointerId]

  addNode: (node) ->
    # We assume a node with the same ID doesn't exist yet.
    @nodes.push(node)
    @nodesById[node.id] = node

  setPointerDestination: (pointerId, destinationNodeId) ->
    maybeExistingPointer = @getPointerById(pointerId)
    if maybeExistingPointer
      maybeExistingPointer.destinationNodeId = destinationNodeId
    else
      pointer = new NewSystem.TreePointer(pointerId, destinationNodeId)
      @pointers.push(pointer)
      @pointersById[pointer.id] = pointer

  makeClone: (cloneId) ->
    return new NewSystem.Tree(
      @nodes.map (node) -> node.clone(cloneId),
      @pointers.map (pointer) -> pointer.clone(cloneId)
    )

  mergeTree: (tree) ->
    for node in tree.nodes
      @addNode(node)
    for pointer in tree.pointers
      @setPointerDestination(pointer.id, pointer.destinationNodeId)

  deparentNode: (nodeId) ->
    parentId = @getNodeById(nodeId).parentId
    if parentId
      @getNodeById(parentId).removeChild(child)

  addChildToNode: (parentId, childId, insertionIndex) ->
    @deparentNode(childId)
    @getNodeById(parentId).childIds.splice(insertionIndex, 0, childId)

  recomputeRedundancies: ->
    # Clear parents
    for node in @nodes
      node.parentId = undefined

    # Assign parents
    for node in @nodes
      for childId in node.childIds
        @getNodeById(childId).parentId = node.id



class NewSystem.Environment
  constructor: (@symbols={}, @mixins={}) ->
    # For now, @symbols maps symbolId => Symbol

  getSymbolById: (symbolId) ->
    @symbols[symbolId]

  addSymbol: (symbolId, symbol) ->
    @symbols[symbolId] = symbol

  addMixin: (mixinId, mixin) ->
    @mixins[mixinId] = mixin

  getTreeForSymbol: (symbolId) ->
    symbol = @getSymbolById(symbolId)
    tree = new NewSystem.Tree()
    symbol.changeList.apply(tree, this)
    return tree

  # Emulates Apparatus's old Node::createVariant
  createVariantOfBuiltinSymbol: (symbolId, masterSymbolId, mixin, changes=[]) ->
    # We assume every builtin symbol has a pointer called 'root' which points at
    # the root node. Our plan:
    # 1. Clone the original node and set its root as the new root.
    # 2. Apply the mixin, to extend the root node.
    # 3. Add on the changes included.

    mixinId = symbolId
    @addMixin(mixinId, mixin)

    allChanges = [
      new NewSystem.Change_CloneSymbol(masterSymbolId, "master")
      new NewSystem.Change_SetPointerDestination("root", NewSystem.NodeRef_Pointer(buildId("master", "root")))
      new NewSystem.Change_ExtendNodeWithMixin(NewSystem.NodeRef_Pointer("root"), mixinId),
      changes...
    ]
    changeList = new NewSystem.ChangeList(allChanges)
    symbol = new NewSystem.Symbol(changeList)
    @addSymbol(symbolId, symbol)


class NewSystem.Symbol
  constructor: (@changeList) ->


class NewSystem.TreeNode
  constructor: (@id, @childIds = [], @linkTargetIds = {}) ->

  removeChild: (childId) ->
    removalIndex = @childIds.indexOf(childId)
    if removalIndex == -1
      throw "Cannot remove a child that doesn't exist"
    @childIds.splice(removalIndex, 1)

  setLinkTarget: (linkName, targetId) ->
    @linkIds[linkName] = targetId

  clone: (cloneId) ->
    return new NewSystem.TreeNode(
      buildId(cloneId, @id),
      @childIds.map((childId) -> buildId(cloneId, childId))
      @linkTargetIds.mapObject((targetId) -> buildId(cloneId, targetId)),
    )

class NewSystem.TreePointer
  constructor: (@id, @destinationNodeId) ->

  clone: (cloneId) ->
    return new NewSystem.TreePointer(
      buildId(cloneId, @id),
      buildId(cloneId, @destinationNodeId)
    )


# NodeRefs are used in changes. They are either node IDs or pointer IDs.

# NodeRefs should not exist in the tree. For instance, a node's children should
# be recorded as good-ol'-fashioned node IDs, not NodeRefs.

# (On the other hand, pointers DO exist in the tree. It's just that they're not
# referred to by other parts of the tree; they exist so that future changes can
# refer to them.)

class NewSystem.NodeRef
  constructor: (@id) ->

  resolve: (tree) ->
    throw "Not implemented"

class NewSystem.NodeRef_Node extends NewSystem.NodeRef
  resolve: (tree) ->
    node = tree.getNodeById(@id)
    if not node
      throw "Node #{@id} does not exist in tree!"
    return node

class NewSystem.NodeRef_Pointer extends NewSystem.NodeRef
  resolve: (tree) ->
    pointer = tree.getPointerById(@id)
    if not pointer
      throw "Pointer #{@id} does not exist in tree!"
    node = tree.getNodeById(pointer.destinationNodeId)
    if not node
      throw "Node #{pointer.destinationNodeId} does not exist in tree!"
    return node


# A "Change" is a description of a change which can be performed to a tree.
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
  constructor: () ->

  apply: (tree, environment) ->
    throw ["Not implemented!", this]

class NewSystem.Change_AddNode extends NewSystem.Change
  constructor: (@newNodeId) ->

  apply: (tree, environment) ->
    # Can't fail!
    tree.addNode(new NewSystem.TreeNode(@newNodeId))

class NewSystem.Change_SetPointerDestination extends NewSystem.Change
  constructor: (@pointerId, @targetRef) ->

  apply: (tree, environment) ->
    tree.setPointerDestination(@pointerId, @targetRef.resolve(tree).id)

class NewSystem.Change_CloneSymbol extends NewSystem.Change
  constructor: (@symbolId, @newCloneId) ->

  apply: (tree, environment) ->
    # Fails if symbol doesn't exist
    symbolTree = environment.getTreeForSymbol(@symbolId)
    clonedTree = symbolTree.makeClone(@newCloneId)
    tree.mergeTree(clonedTree)

class NewSystem.Change_AddChild extends NewSystem.Change
  constructor: (@parentRef, @childRef, @insertionIndex) ->

  apply: (tree, environment) ->
    # Fails if either parent or child doesn't exist
    parent = @parentRef.resolve(tree)
    child = @childRef.resolve(tree)
    tree.addChildToNode(parent.id, child.id, @insertionIndex)

class NewSystem.Change_DeparentNode extends NewSystem.Change
  constructor: (@nodeRef) ->

  apply: (tree, environment) ->
    # Fails if child doesn't exist
    node = @nodeRef.resolve(tree)
    tree.deparentNode(node.id)

class NewSystem.Change_ExtendNodeWithMixin extends NewSystem.Change
  constructor: (@nodeRef, @mixinId) ->

  apply: (tree, environment) ->
    # Fails if node doesn't exist or mixin doesn't exist
    node = @nodeRef.resolve(tree)
    node.extend(environment.getMixinById(@mixinId))

class NewSystem.Change_ExtendNodeWithLiteral extends NewSystem.Change
  constructor: (@nodeRef, @literal) ->

  apply: (tree, environment) ->
    node = @nodeRef.resolve(tree)
    node.extend(@literal)

class NewSystem.Change_SetNodeLinkTarget extends NewSystem.Change
  constructor: (@nodeRef, @linkName, @targetRef) ->

  apply: (tree, environment) ->
    # Fails if node or target don't exist

    node = @nodeRef.resolve(tree)
    target = @targetRef.resolve(tree)

    node.setLinkTarget(@linkName, target.id)


class NewSystem.ChangeList
  constructor: (@changes=[]) ->

  apply: (tree, environment) ->
    for change in @changes
      tree.recomputeRedundancies()
      change.apply(tree, environment)
    tree.recomputeRedundancies()

  addChange: (change) ->
    @changes.push(change)


# NewSystem.Test_ChangeEnvironment = new NewSystem.ChangeEnvironment(
#   [
#     Group: new NewSystem.ChangeList [
#       new NewSystem.Change_AddNode("groupNode"),
#       new NewSystem.Change_CloneSymbol("Transform", "transform"),
#       new NewSystem.Change_AddChild("groupNode", "transform/transformNode", 0),
#     ]
#     Transform: new NewSystem.ChangeList [
#       new NewSystem.Change_AddNode("transformNode"),
#     ]
#   ],
#   [
#
#   ]
# )
