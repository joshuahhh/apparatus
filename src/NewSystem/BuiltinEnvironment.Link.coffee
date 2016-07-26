_ = require "underscore"
NewSystem = require "./NewSystem"


module.exports = (BuiltinEnvironment) ->
  # The use of "Link" to link attributes to their dependencies has been removed
  # in NewSystem. However, for other uses (ControlledAttributeLink, ?), we keep
  # Link around.

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Link", "Node",
    {
      label: "Link"

      target: ->
        @node.linkTargetBundles()["old_school_link"]
    }

  BuiltinEnvironment.addCompoundChangeType "SetOldSchoolLinkTarget", ({linkId, linkTargetId}) ->
    [
      {type: "SetNodeLinkTarget", nodeId: linkId, linkId: "old_school_link", targetId: linkTargetId}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "ControlledAttributeLink", "Link",
    {
      label: "Controlled-Attribute Link"

      isControlledAttributeLink: ->
        true
    }
