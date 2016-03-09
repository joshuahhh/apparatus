Node = require "./Node"

module.exports = Link = Node.createVariant
  label: "Link"

  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    # Because the _resolvedTarget properly is not inherited, it is initialized
    # in the constructor for every Link.
    @_resolvedTarget = null

    # NOTE: We assume that, for this link, @_resolvedTarget is a function of
    # @_target. If there are structural changes which modify @_resolvedTarget
    # without affecting @_target, things will break, and we will need a more
    # sophisticated form of memoization.

  setTarget: (newTarget) ->
    @deregisterFromTarget()
    @_target = newTarget
    @_resolvedTarget = null

  target: ->
    return @_resolvedTarget if @_resolvedTarget

    # First, trace backwards from me to the link which originally established
    # the target. Keep track of the heads of each of the nodes along the way.
    headStack = []
    cursor = this
    while !cursor.hasOwnProperty("_target")
      headStack.unshift(cursor.head())
      cursor = cursor.master()

    # Now, trace forwards from the original target to the target within my
    # variation.
    cursor = @_target
    for head in headStack
      nextCursor = cursor.findVariantWithHead(head)

      # What does it mean if nextCursor is not found? TODO: think about this
      # possibility.
      break unless nextCursor?

      cursor = nextCursor

    cursor.registerIncomingLink(this)
    @_resolvedTarget = cursor
    return cursor

  deregisterFromTarget: ->
    if @_resolvedTarget
      @target().deregisterIncomingLink(this)
