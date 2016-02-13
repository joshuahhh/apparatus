Node = require "./Node"

module.exports = Link = Node.createVariant
  label: "Link"

  setTarget: (newTarget) ->
    @deregisterFromTarget()
    @_target = newTarget
    @_registered = false

  target: ->
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
    @_registered = true
    return cursor

  deregisterFromTarget: ->
    if @_registered
      @target().deregisterIncomingLink(this)
