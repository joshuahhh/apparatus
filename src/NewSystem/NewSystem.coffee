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

NewSystem.buildId = (args...) -> args.join("/")

class NewSystem.Tree
  constructor: (@nodes = [], @cloneOrigins = []) ->
    # NOTE: A Tree takes ownership of its nodes – they cannot be shared between
    # trees.

    @redundanciesUpToDate = false

    # console.log('Tree::constructor', _.pluck(@nodes, 'id'))

    for node in @nodes
      node.tree = this

  getNodeById: (nodeId, okIfNotExists) ->
    @recomputeRedundancies()
    toReturn = @nodesById[nodeId]
    if not okIfNotExists and not toReturn
      console.log(_.pluck(@nodes, "id"))
      console.trace()
      throw "Node #{nodeId} does not exist in tree!"
    return toReturn

  addNode: (node) ->
    # We assume a node with the same ID doesn't exist yet.
    @nodes.push(node)
    node.tree = this
    @redundanciesUpToDate = false

  makeClone: (symbolId, cloneId) ->
    toReturn = new NewSystem.Tree(
      @nodes.map((node) -> node.clone(cloneId)),
      @cloneOrigins.map((cloneOrigin) -> cloneOrigin.clone(cloneId))
        .concat([new NewSystem.TreeCloneOrigin(cloneId, symbolId)])
    )
    return toReturn

  mergeTree: (tree) ->
    for node in tree.nodes
      @addNode(node)
    @cloneOrigins.push(tree.cloneOrigins...)
    @redundanciesUpToDate = false

  deparentNode: (nodeId) ->
    parentId = @getNodeById(nodeId).parentId
    if parentId
      @getNodeById(parentId).removeChild(nodeId)
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
      toReturn += "      constructors: #{JSON.stringify(node.constructors)}\n"
    toReturn += "}\n"
    return toReturn


class NewSystem.Environment
  constructor: (@symbols = {}, @mixins = {}, @changeTypes = {}) ->
    # For now, @symbols maps symbolId => Symbol

  getSymbolById: (symbolId) ->
    @symbols[symbolId]

  addSymbol: (symbolId, symbol) ->
    @symbols[symbolId] = symbol

  getMixinById: (mixinId) ->
    @mixins[mixinId]

  addMixin: (mixinId, mixin) ->
    @mixins[mixinId] = mixin

  getChangeTypeById: (changeTypeId) ->
    @changeTypes[changeTypeId]

  addChangeType: (changeTypeId, changeType) ->
    changeType.id = changeTypeId
    @changeTypes[changeTypeId] = changeType

  addAtomicChangeType: (changeTypeId, applyFunc) ->
    @addChangeType(changeTypeId, new NewSystem.AtomicChangeType(applyFunc))

  addCompoundChangeType: (changeTypeId, expandFunc) ->
    @addChangeType(changeTypeId, new NewSystem.CompoundChangeType(expandFunc))

  resolveChange: (change) ->
    changeType = @getChangeTypeById(change.type)
    if not changeType
      console.log _.keys(@changeTypes)
      throw "Change type #{change.type} not found!"

    return new NewSystem.ResolvedChange(changeType, _.omit(change, "type"))

  getTreeForSymbol: (symbolId) ->
    # IMPORTANT: Do not mutate the result of this method! It's a tree which
    # belongs to the symbol itself! You should view it, or clone it.

    symbol = @getSymbolById(symbolId)
    if not symbol
      throw "Symbol #{symbolId} not found in environment!"
    return symbol.getTree(this)

  # Emulates Apparatus's old Node::createVariant
  createVariantOfBuiltinSymbol: (symbolId, masterSymbolId, mixin, changes = []) ->
    # We assume every builtin symbol has a node called 'root'.
    # 1. Clone the original node as master.
    # 2. Apply the mixin, to extend the root node.
    # 3. Add on the changes included.

    mixinId = symbolId
    @addMixin(mixinId, mixin)

    if masterSymbolId
      rootChange = {type: "CloneSymbol", symbolId: masterSymbolId, cloneId: ""}
    else
      # If "masterSymbolId" is undefined, then we're starting from a bare node,
      # instead of making a variant of an existing symbol. (This is used for
      # defining the traditional Apparatus "Node".)
      rootChange = {type: "AddNode", nodeId: "root"}

    allChanges = [
      rootChange
      {type: "ExtendNodeWithMixin", nodeId: "root", mixinId: mixinId}
      changes...
    ]
    changeList = new NewSystem.ChangeList(allChanges)
    symbol = new NewSystem.Symbol(changeList)
    @addSymbol(symbolId, symbol)


class NewSystem.CompoundEnvironment extends NewSystem.Environment
  constructor: (@childEnvironments = []) ->

  getSymbolById: (symbolId) ->
    for childEnvironment in @childEnvironments
      maybeSymbol = childEnvironment.getSymbolById(symbolId)
      if maybeSymbol then return maybeSymbol

  addSymbol: (symbolId, symbol) ->
    throw "Not implemented: CompoundEnvironment is read-only"

  getMixinById: (mixinId) ->
    for childEnvironment in @childEnvironments
      maybeMixin = childEnvironment.getMixinById(mixinId)
      if maybeMixin then return maybeMixin

  addMixin: (mixinId, mixin) ->
    throw "Not implemented: CompoundEnvironment is read-only"

  getChangeTypeById: (changeTypeId) ->
    for childEnvironment in @childEnvironments
      maybeChangeType = childEnvironment.getChangeTypeById(changeTypeId)
      if maybeChangeType then return maybeChangeType

  addChangeType: (changeTypeId, changeType) ->
    throw "Not implemented: CompoundEnvironment is read-only"


class NewSystem.Symbol
  constructor: (@changeList) ->
    @__numChangesApplied = 0
    @__tree = new NewSystem.Tree()

  getTree: (environment) ->
    # IMPORTANT: Do not mutate the result of this method! It's a tree which
    # belongs to the symbol itself! You should view it, or clone it.

    # TODO: assumes the change-list is append only
    @changeList.apply(@__tree, environment, @__numChangesApplied)
    @__numChangesApplied = @changeList.numChanges()
    return @__tree


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
    maybeBuildId = (id) ->
      if cloneId
        NewSystem.buildId(cloneId, id)
      else
        id

    newNode = new NewSystem.TreeNode(
      maybeBuildId(@id)
      @childIds.map maybeBuildId
      _.mapObject @linkTargetIds, maybeBuildId
      Object.create(@bundle),  # We use prototypes only for efficiency, not dynamics!
      @constructors.slice(0)  # UGH WHAT A BUG; where are my immutable data structures...
    )

    for [methodName, methodArguments] in @constructors
      newNode.runConstructor(methodName, methodArguments)

    return newNode

  extendBundle: (obj) ->
    _.extend @bundle, obj

  runConstructorAndRemember: (methodName, methodArguments=[]) ->
    @runConstructor(methodName, methodArguments)
    @constructors.push([methodName, methodArguments])

  runConstructor: (methodName, methodArguments=[]) ->
    method = @bundle[methodName]
    if not method
      throw "Cannot find method #{methodName} in node #{@id}!"
    method.apply(@bundle, methodArguments)

  ################################
  # These require knowing @tree: #
  ################################

  childNodes: ->
    @tree.getNodeById(childId) for childId in @childIds

  childNodesOfType: (predicateName) ->
    _.filter @childNodes(), (childNode) ->
      predicateProp = childNode.bundle[predicateName]
      predicateProp && predicateProp()

  linkTargetNodes: ->
    # console.log('Node::linkTargetNodes', @linkTargetIds, @tree)
    _.mapObject @linkTargetIds, (targetId) => @tree.getNodeById(targetId)

  parentNode: ->
    @tree.getNodeById()

class NewSystem.TreeCloneOrigin
  constructor: (@id, @symbolId) ->

  clone: (cloneId) ->
    return new NewSystem.TreeCloneOrigin(
      NewSystem.buildId(cloneId, @id),
      @symbolId
    )

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


# A ChangeType (instance of NewSystem.ChangeType) is a type of change, as you might refer
# to with a name such as "AddChild" or "SetAttributeExpression".

class NewSystem.ChangeType
  apply: (parameters, tree, environment) ->
    throw ["Not implemented!", this]

  propValueToString: (propName, propValue) ->
    # to be overridden in special cases
    return propValue?.toString()

class NewSystem.AtomicChangeType
  constructor: (@applyFunc) ->

  apply: (parameters, tree, environment) ->
    @applyFunc(parameters, tree, environment)

class NewSystem.CompoundChangeType
  constructor: (@expandFunc) ->

  expand: (parameters) ->
    return @expandFunc(parameters)

  apply: (parameters, tree, environment) ->
    expanded = @expand(parameters)
    for change in expanded
      environment.resolveChange(change).apply(tree, environment)


indent = (text, spaces) ->
  text
    .split("\n")
    .map((line) -> "            ".substring(0, spaces) + line)
    .join("\n")

indentLevel = 0

# A ResolvedChange (instance of NewSystem.ResolvedChange) is a resolved
# ChangeType together with a set of parameters. It is ready to be applied to a
# tree!

class NewSystem.ResolvedChange
  constructor: (@changeType, @parameters) ->

  apply: (tree, environment) ->
    @changeType.apply(@parameters, tree, environment)

  toString: ->
    propStrings = for own paramName, paramValue of @parameters
      "#{propName} = #{@changeType.propValueToString(propName, propValue)}"
    return @changeType.id + ": " + propStrings.join(", ")

class NewSystem.ChangeList
  constructor: (@changes = []) ->

  toString: ->
    toReturn = ""
    numberStringWidth = Math.ceil(Math.log10((@numChanges() - 1) or 1))
    for change, i in @changes
      numberString = "#{i}"
      numberString = new Array((numberStringWidth - numberString.length) + 1).join(" ") + numberString
      toReturn += "#{numberString}. #{change.toString()}\n"
    return toReturn

  apply: (tree, environment, from=0) ->
    for change, i in @changes.slice(from)
      if _.isArray(change)
        console.error(change)
        throw "ChangeLists should contain Changes, not arrays!"
      tree.recomputeRedundancies()
      # console.log("Running change #{i + 1}/#{@changes.length} in ChangeList: ", JSON.stringify(change))
      resolvedChange = environment.resolveChange(change)
      resolvedChange.apply(tree, environment)
    tree.recomputeRedundancies()

  addChange: (change) ->
    @changes.push(change)

  addChanges: (changes) ->
    @changes.push(changes...)

  numChanges: ->
    @changes.length

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


# 2016-07-25
#
# Recent thoughts:
#
# 1. createVariantOfBuiltinSymbol should probably make shortcuts for ALL
# pointers on the master, not just "root". So when you define Shape, you make a
# pointer "transform" to the TransformComponent, and then that pointer persists
# even as you define different nth-order clones of Shape. This way, you don't
# need to count out "master"s when you want to refer to some Shape's transform.
# Not sure how this fits with the desire to have createVariantOfBuiltinSymbol be
# "static" (not depend on rendered trees) – how do we know what pointers exist
# and should be cloned? One way to keep it static: explicitly list which
# pointers should be rewritten. Another way to keep it static: make rewriting
# pointers part of a Change. For instance, there could be an argument to
# Change_CloneSymbol called "copyPointers".
#
# 2. I am troubled by the fragility of node IDs, as determined by the cloning
# hierarchy. For instance, if I want to change how Attributes work, by adding a
# new "superclass", then this will change the node-IDs of all attributes. My
# hope, that existing user-change-lists would be compatible with the new
# BuiltinEnvironment, would fail, if the user changes refer to attributes using
# their whole node ID.
#
# 3. OH WAIT the above two issues (really one issue) can be resolved if we have
# a concept of a "primary" cloning operation (of a symbol which could be called
# a "master"), which, rather than just preserving pointers, actually preserves
# node IDs. When you perform a primary-clone, you don't prepend a clone-id to
# the node IDs; you keep them as they are. I think this makes a lot of sense. My
# one concern is, what happens to our ability to apply new changes in the
# definitions of cloned symbols "in place"? (This isn't something we support
# now, and it might never be, but I was happy that I was keeping the door open
# to this feature, or ones like it.) Well, let's think this out: If we wanted to
# have a feature like this, we'd need to keep track of what clones exist in our
# tree (no matter what). So we have some list of cloning-ids, together with
# their origins and relevant metadata. This list would necessarily NOT be
# affected by the node-id compression: it would use paths with "master". (We
# need to distinguish from "master" and "master/master" clonings!) So then, if
# we wanted to apply a change to, say, the "master/master/transform/master"
# cloning, we would take the local node ids in the change and prepend
# "transform" to put them in context. I guess the "master"s don't really matter
# here? OK this is confusing but my intuition is that everything still works.
# Let's do this!
