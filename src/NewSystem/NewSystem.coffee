_ = require "underscore"
util = require "util"


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
  constructor: (@nodes = [], @pointers = [], @cloneOrigins = []) ->
    # NOTE: A Tree takes ownership of its nodes and pointers – they cannot be
    # shared between trees.

    @redundanciesUpToDate = false

    # console.log('Tree::constructor', _.pluck(@nodes, 'id'))

    for node in @nodes
      node.tree = this

    for pointer in @pointers
      pointer.tree = this

  getNodeById: (nodeId) ->
    @recomputeRedundancies()
    return @nodesById[nodeId]

  getPointerById: (pointerId) ->
    @recomputeRedundancies()
    return @pointersById[pointerId]

  addNode: (node) ->
    # We assume a node with the same ID doesn't exist yet.
    @nodes.push(node)
    node.tree = this
    @redundanciesUpToDate = false

  setPointerDestination: (pointerId, destinationNodeId) ->
    maybeExistingPointer = @getPointerById(pointerId)
    if maybeExistingPointer
      maybeExistingPointer.destinationNodeId = destinationNodeId
    else
      pointer = new NewSystem.TreePointer(pointerId, destinationNodeId)
      pointer.tree = this
      @pointers.push(pointer)
      @pointersById[pointer.id] = pointer
    @redundanciesUpToDate = false

  makeClone: (cloneId, symbolId) ->
    toReturn = new NewSystem.Tree(
      @nodes.map((node) -> node.clone(cloneId)),
      @pointers.map((pointer) -> pointer.clone(cloneId)),
      @cloneOrigins.map((cloneOrigin) -> cloneOrigin.clone(cloneId))
        .concat([new NewSystem.TreeCloneOrigin(cloneId, symbolId)])
    )
    return toReturn

  mergeTree: (tree) ->
    for node in tree.nodes
      @addNode(node)
    for pointer in tree.pointers
      @setPointerDestination(pointer.id, pointer.destinationNodeId)
    @cloneOrigins.push(tree.cloneOrigins...)
    @redundanciesUpToDate = false

  deparentNode: (nodeId) ->
    parentId = @getNodeById(nodeId).parentId
    if parentId
      @getNodeById(parentId).removeChild(child)
    @redundanciesUpToDate = false

  addChildToNode: (parentId, childId, insertionIndex) ->
    @deparentNode(childId)
    @getNodeById(parentId).childIds.splice(insertionIndex, 0, childId)
    @redundanciesUpToDate = false

  recomputeRedundancies: ->
    if @redundanciesUpToDate
      return

    # we pretend we're up to date, to avoid infinite recursion, but make sure
    # you do things in the right order!
    @redundanciesUpToDate = true

    @nodesById = _.indexBy(@nodes, "id")
    @pointersById = _.indexBy(@pointers, "id")

    # Clear parents
    for node in @nodes
      node.parentId = undefined

    # Clear parents
    for node in @nodes
      node.parentId = undefined

    # Assign parents
    for node in @nodes
      for childId in node.childIds
        @getNodeById(childId).parentId = node.id

  stripRedundancies: ->
    delete @nodesById
    delete @pointersById

    # Clear parents
    for node in @nodes
      delete node.parentId

    # Clear parents
    for node in @nodes
      delete node.parentId

    @redundanciesUpToDate = false

  toString: ->
    toReturn  = "Tree {\n"
    toReturn += "  nodes:\n"
    for node in @nodes
      toReturn += "    #{node.id}:\n"
      toReturn += "      children: #{node.childIds.join(",")}\n"
      toReturn += "      links:\n"
      for linkKey, targetId of node.linkTargetIds
        toReturn += "        #{linkKey}: #{targetId}\n"
      toReturn += "      bundle: [#{_.allKeys(node.bundle).join(", ")}]\n"
    toReturn += "  pointers:\n"
    for pointer in @pointers
      toReturn += "    #{pointer.id}: #{pointer.destinationNodeId}\n"
    toReturn += "}\n"
    return toReturn


class NewSystem.Environment
  constructor: (@symbols = {}, @mixins = {}) ->
    # For now, @symbols maps symbolId => Symbol

  getSymbolById: (symbolId) ->
    @symbols[symbolId]

  addSymbol: (symbolId, symbol) ->
    @symbols[symbolId] = symbol

  getMixinById: (mixinId) ->
    @mixins[mixinId]

  addMixin: (mixinId, mixin) ->
    @mixins[mixinId] = mixin

  getTreeForSymbol: (symbolId) ->
    symbol = @getSymbolById(symbolId)
    tree = new NewSystem.Tree()
    symbol.changeList.apply(tree, this)
    return tree

  # Emulates Apparatus's old Node::createVariant
  createVariantOfBuiltinSymbol: (symbolId, masterSymbolId, mixin, changes = []) ->
    # We assume every builtin symbol has a pointer called 'root' which points at
    # the root node. Our plan:
    # 1. Clone the original node and set its root as the new root.
    # 2. Apply the mixin, to extend the root node.
    # 3. Add on the changes included.

    mixinId = symbolId
    @addMixin(mixinId, mixin)

    allChanges = [
      new NewSystem.Change_CloneSymbol(masterSymbolId, "master")
      new NewSystem.Change_SetPointerDestination("root", new NewSystem.NodeRef_Pointer(buildId("master", "root")))
      new NewSystem.Change_ExtendNodeWithMixin(new NewSystem.NodeRef_Pointer("root"), mixinId),
      changes...
    ]
    changeList = new NewSystem.ChangeList(allChanges)
    symbol = new NewSystem.Symbol(changeList)
    @addSymbol(symbolId, symbol)


class NewSystem.Symbol
  constructor: (@changeList) ->


class NewSystem.TreeNode
  constructor: (@id, @childIds = [], @linkTargetIds = {}, @bundle = {}, @constructors = []) ->
    @bundle.node = this

  removeChild: (childId) ->
    removalIndex = @childIds.indexOf(childId)
    if removalIndex == -1
      throw "Cannot remove a child that doesn't exist"
    @childIds.splice(removalIndex, 1)
    @tree?.redundanciesUpToDate = false

  setLinkTarget: (linkKey, targetId) ->
    @linkTargetIds[linkKey] = targetId
    @tree?.redundanciesUpToDate = false

  removeAllLinks: ->
    @linkTargetIds = {}

  clone: (cloneId) ->
    newNode = new NewSystem.TreeNode(
      buildId(cloneId, @id)
      @childIds.map (childId) -> buildId(cloneId, childId)
      _.mapObject @linkTargetIds, (targetId) -> buildId(cloneId, targetId)
      Object.create(@bundle),  # We use prototypes only for efficiency, not dynamics!
      @constructors
    )

    for [methodName, methodArguments] in @constructors
      # console.log("running constructor #{methodName} to turn #{@id} into #{newNode.id}")
      newNode.runConstructor(methodName, methodArguments)

    return newNode

  extendBundle: (obj) ->
    _.extend @bundle, obj

  nodeRefTo: ->
    new NewSystem.NodeRef_Node(@id)

  runConstructorAndRemember: (methodName, methodArguments=[]) ->
    @runConstructor(methodName, methodArguments)
    @constructors.push([methodName, methodArguments])

  runConstructor: (methodName, methodArguments=[]) ->
    method = @bundle[methodName]
    method.apply(@bundle, methodArguments)

  # These require knowing @tree:

  childNodes: ->
    @tree.getNodeById(childId) for childId in @childIds

  childNodesOfType: (predicateName) ->
    _.filter @childNodes(), (childNode) ->
      predicateProp = childNode[predicateName]
      predicateProp && predicateProp()

  linkTargetNodes: ->
    # console.log('Node::linkTargetNodes', @linkTargetIds, @tree)
    _.mapObject @linkTargetIds, (targetId) => @tree.getNodeById(targetId)

class NewSystem.TreePointer
  constructor: (@id, @destinationNodeId) ->

  clone: (cloneId) ->
    return new NewSystem.TreePointer(
      buildId(cloneId, @id),
      buildId(cloneId, @destinationNodeId)
    )

class NewSystem.TreeCloneOrigin
  constructor: (@id, @symbolId) ->

  clone: (cloneId) ->
    return new NewSystem.TreeCloneOrigin(
      buildId(cloneId, @id),
      @symbolId
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
    return

class NewSystem.Change_SetPointerDestination extends NewSystem.Change
  constructor: (@pointerId, @targetRef) ->

  apply: (tree, environment) ->
    tree.setPointerDestination(@pointerId, @targetRef.resolve(tree).id)
    return

class NewSystem.Change_CloneSymbol extends NewSystem.Change
  constructor: (@symbolId, @newCloneId) ->
    if not @newCloneId
      throw "Change_CloneSymbol needs a newCloneId!"

  apply: (tree, environment) ->
    # Fails if symbol doesn't exist
    symbolTree = environment.getTreeForSymbol(@symbolId)
    clonedTree = symbolTree.makeClone(@newCloneId, @symbolId)
    tree.mergeTree(clonedTree)
    return

# PARENTS AND CHILDREN

class NewSystem.Change_AddChild extends NewSystem.Change
  constructor: (@parentRef, @childRef, @insertionIndex) ->

  apply: (tree, environment) ->
    # Fails if either parent or child doesn't exist
    parent = @parentRef.resolve(tree)
    child = @childRef.resolve(tree)
    tree.addChildToNode(parent.id, child.id, @insertionIndex)
    return

class NewSystem.Change_DeparentNode extends NewSystem.Change
  constructor: (@nodeRef) ->

  apply: (tree, environment) ->
    # Fails if child doesn't exist
    node = @nodeRef.resolve(tree)
    tree.deparentNode(node.id)
    return

# LINKS

class NewSystem.Change_SetNodeLinkTarget extends NewSystem.Change
  constructor: (@nodeRef, @linkKey, @targetRef) ->

  apply: (tree, environment) ->
    # Fails if node or target don't exist

    node = @nodeRef.resolve(tree)
    target = @targetRef.resolve(tree)
    node.setLinkTarget(@linkKey, target.id)
    return

class NewSystem.Change_RemoveNodeLink extends NewSystem.Change
  constructor: (@nodeRef, @linkKey) ->

  apply: (tree, environment) ->
    # Fails if node doesn't exist

    node = @nodeRef.resolve(tree)
    node.setLinkTarget(@linkKey, undefined)
    return

class NewSystem.Change_RemoveAllLinks extends NewSystem.Change
  constructor: (@nodeRef) ->

  apply: (tree, environment) ->
    # Fails if node doesn't exist

    node = @nodeRef.resolve(tree)
    node.removeAllLinks()
    return

# IN THE BUNDLE

class NewSystem.Change_ExtendNodeWithMixin extends NewSystem.Change
  constructor: (@nodeRef, @mixinId) ->

  apply: (tree, environment) ->
    # Fails if node doesn't exist or mixin doesn't exist
    node = @nodeRef.resolve(tree)
    node.extendBundle(environment.getMixinById(@mixinId))
    return

class NewSystem.Change_ExtendNodeWithLiteral extends NewSystem.Change
  constructor: (@nodeRef, @literal) ->

  apply: (tree, environment) ->
    # Fails if node doesn't exist
    node = @nodeRef.resolve(tree)
    node.extendBundle(@literal)
    return

class NewSystem.Change_RunConstructor extends NewSystem.Change
  constructor: (@nodeRef, @methodName, @methodArguments = []) ->

  apply: (tree, environment) ->
    # Fails if node or method don't exist

    node = @nodeRef.resolve(tree)
    node.runConstructorAndRemember(@methodName, @methodArguments)
    return

class NewSystem.Change_Log extends NewSystem.Change
  constructor: () ->

  apply: (tree, environment) ->
    console.log tree
    return

indent = (text, spaces) ->
  text
    .split("\n")
    .map((line) -> "            ".substring(0, spaces) + line)
    .join("\n")

indentLevel = 0

class NewSystem.ChangeList
  constructor: (@changes = []) ->

  apply: (tree, environment) ->
    for change, i in @changes
      # console.log(indent("change #{i}: #{util.inspect(change, false, null)}", indentLevel))
      # console.log(indent("before:", indentLevel))
      # console.log(indent(tree.toString(), indentLevel))
      # indentLevel += 2
      tree.recomputeRedundancies()
      change.apply(tree, environment)
      # indentLevel -= 2
      # console.log(indent("after:", indentLevel))
      # console.log(indent(tree.toString(), indentLevel))
    tree.recomputeRedundancies()

  addChange: (change) ->
    @changes.push(change)

# 2016-07-18
#
# A case study on CLONING and CONSTRUCTORS:
#
# Apparatus nodes sometimes need complex bits of mutable state which require
# per-node set-up. For instance, Attributes have a @value Dataflow cell which
# needs to be hooked up to the right value function, bound to the right `this`.
# (NOTE: Some of this state could maybe be re-engineered? But let's put that
# aside for now.) This means that for every Attribute which is added to a
# diagram, directly or indirectly (through nth-order cloning), we need to run
# some set-up code.
#
# At first I thought I had a good solution to this: add a "RunMethod" change to
# the Attribute symbol's changelist. But with the current cloning system
# (construct-then-copy), this doesn't work: the constructed mutable state
# refers to the ORIGINAL nodes, and when you clone them, it is misdirected.
#
# If we used the construct-in-place cloning system, this wouldn't be a problem,
# since the "RunMethod" change would be running on what would ultimately be the
# final node in the diagram.
#
# But I am wary of adopting construct-in-place, since it means we can't keep
# around pre-built trees to clone as needed... it shuts off a LOT of
# opportunities for memoization. (Implementation is also a liiittle bit tricky,
# since you need to keep the context of what "place" you're cloning into around
# for everything you do, rather than just ignoring it, and having a single
# centralized copy method.)
#
# How can we implement constructor (or constructor-like) behavior in a
# construct-then-copy world? One option is just to do what Apparatus does now:
# have constructors, and run them on copy. I am wary of this for exactly one
# reason: how do you stack up constructors? Does each constructor have to refer
# to previous ones explicitly? Can we just assume they run in order, and
# maintain a constructor queue? (I really don't want to rely on JS inheritance
# bullshit, or have nodes referring to their "masters". NO SLAVES, NO MASTERS.)
# Or maybe we can keep the existing API, with "RunMethod", but keep a "methods
# to run on copy" queue? That sounds real slick. I think I'll do that for now.
# (But I think I'll switch to calling them "constructors", since that makes
# their semantics more clear?)

# 2016-07-18
#
# On what changes can be:
#
# So I coded up a bunch of "changesForX" methods, which take a living node and
# generate a list of changes which achieve a given effect. I used them in tests
# and everything looked great.
#
# I was implementing Element::changesForAddVariable, and it seemed clear that it
# should call Attribute::changesForSetExpression. I realized I was in trouble:
# changesForX methods live on live nodes, but they're supposed to construct
# static representations of potential future changes. How can I call
# changesForSetExpression on attributes which I am only imagining and never
# actually creating?
#
# I saw two roads forward:
#
# 1. Change the interface that changesForX methods work with, so that they
# actually perform the changes as they go, and can refer to intermediate
# products when deriving future changes in the list.
#
# 2. Design the set of changes so that you never need access to live nodes to
# construct compound change-lists. Better way to put this: design the set of
# changes so that all "changesForX" methods can be static methods. (That way,
# Element::changesForAddVariable can call Attribute::changesForSetExpression.)
#
# Thinking about it, I realized that "never need[ing] access to live nodes to
# construct compound change-lists" was actually a requirement for another
# important reason: robustness of changes to modifications of earlier cloned
# symbols. Attribute::changesForSetExpression is a very good example here. In
# its current implementation, it looks at existing references and pushes changes
# to remove them. Those individual changes then become the permanent source of
# truth on the symbol's change-list. But what if you're setting an expression
# which comes from a cloned symbol, and the symbol's expression changes to have
# different references? The individual reference-removals you hard-coded on the
# change-list are no longer valid, and your diagram will be corrupted.
#
# So there's actually an elegant convenience here: by writing your changesForX
# methods statically, you ensure they don't rely on any tree state (other than
# the explicitly provided arguments), which is likely to make change-lists more
# robust. I like this a lot.
#
# To be clear, this requires that more types of changes be implemented. You
# can't just depend on some RISC. But I like this, because higher-level changes
# do a better job of expressing programmer intent, and can do a better job of
# accurately performing this intent in a shifting environment.

# 2016-07-19
#
# On IDs:
#
# change_X functions shouldn't call Util.generateId(), since this introduces
# non-determinism, and these functions are used to set up the built-in
# environment. Util.generateId() should only really be called by the UI, in
# response to user interactions.