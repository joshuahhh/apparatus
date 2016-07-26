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
      toReturn += "#{numberString}. #{JSON.stringify(change)}\n"
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
