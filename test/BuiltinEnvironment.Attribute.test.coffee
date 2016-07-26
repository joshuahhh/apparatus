test = require("tape")
util = require("util")
_ = require("underscore")

NewSystem = require("../src/NewSystem/NewSystem")
BuiltinEnvironment = require("../src/NewSystem/BuiltinEnvironment")


# test "BuiltinEnvironment looks niiiiice", (t) ->
#   console.log(util.inspect(BuiltinEnvironment, false, null));
#   t.end()
#
# test "Make a node", (t) ->
#   tree = new NewSystem.Tree()
#   change = new NewSystem.Change_CloneSymbol("Node", "myCloneId")
#   change.apply(tree, BuiltinEnvironment)
#   console.log(tree.toString())
#   # console.log(util.inspect(BuiltinEnvironment, false, null));
#   t.end()


makeAttribute = (tree, attributeId) ->
  change = {type: "CloneSymbol", symbolId: "Attribute", cloneId: attributeId}
  resolvedChange = BuiltinEnvironment.resolveChange(change)
  resolvedChange.apply(tree, BuiltinEnvironment)
  return tree.getNodeById("#{attributeId}/root")


setExpression = (tree, attribute, exprString, references) ->
  change = {type: "SetAttributeExpression", attributeId: attribute.id, exprString: exprString, references: references}
  resolvedChange = BuiltinEnvironment.resolveChange(change)
  resolvedChange.apply(tree, BuiltinEnvironment)


test "Simple attribute test", (t) ->
  tree = new NewSystem.Tree()
  attribute1 = makeAttribute(tree, "attribute1")
  attribute2 = makeAttribute(tree, "attribute2")

  console.log("attribute2.id", attribute2.id)
  setExpression(tree, attribute1, "testing", {a: attribute2.id})
  t.equal(attribute1.bundle.exprString, "testing", "exprString set correctly")
  t.equal(attribute1.linkTargetIds['a'], attribute2.id, "link target set correctly")

  t.end()

test "Ported: 'Numbers work'", (t) ->
  tree = new NewSystem.Tree()
  a = makeAttribute(tree, "a")

  setExpression(tree, a, "6")
  t.equal(a.bundle.exprString, "6", "exprString set correctly")
  t.equal(a.bundle.value(), 6, "attribute evaluates correctly")

  t.end()

test "Ported: 'Math expressions work'", (t) ->
  tree = new NewSystem.Tree()
  a = makeAttribute(tree, "a")

  setExpression(tree, a, "5 + 5")
  t.equal(a.bundle.exprString, "5 + 5", "exprString set correctly")
  t.equal(a.bundle.value(), 10, "attribute evaluates correctly")

  t.end()

test "Ported: 'Math expressions work'", (t) ->
  tree = new NewSystem.Tree()
  a = makeAttribute(tree, "a")
  b = makeAttribute(tree, "b")

  setExpression(tree, a, "20")
  setExpression(tree, b, "$$$a$$$ * 2", {$$$a$$$: a.id})
  t.equal(a.tree, tree, "a has the right .tree reference")
  t.equal(b.tree, tree, "b has the right .tree reference")
  t.equal(b.bundle.value(), 40, "attribute evaluates correctly")

  t.end()

test "Ported: 'Changes recompile'", (t) ->
  tree = new NewSystem.Tree()
  a = makeAttribute(tree, "a")
  b = makeAttribute(tree, "b")

  setExpression(tree, a, "20")
  setExpression(tree, b, "$$$a$$$ * 2", {$$$a$$$: a.id})
  t.equal(b.bundle.value(), 40)

  setExpression(tree, a, "10")
  t.equal(b.bundle.value(), 20)

  setExpression(tree, b, "$$$a$$$ * 3", {$$$a$$$: a.id})
  t.equal(b.bundle.value(), 30)

  t.end()

test "Ported: 'Dependencies work'", (t) ->
  tree = new NewSystem.Tree()
  a = makeAttribute(tree, "a")
  b = makeAttribute(tree, "b")
  c = makeAttribute(tree, "c")

  setExpression(tree, a, "$$$b$$$ * 2", {$$$b$$$: b.id})
  setExpression(tree, b, "$$$c$$$ * 3", {$$$c$$$: c.id})
  setExpression(tree, c, "20")

  t.equal(a.bundle.value(), 120, 'value works')
  t.deepEqual(a.bundle.dependencies(), [b.bundle, c.bundle], 'dependencies works')
  t.equal(a.bundle.circularReferencePath(), null, 'circularReferencePath works')

  t.end()

test "Ported: 'Dependencies work with circular references'", (t) ->
  tree = new NewSystem.Tree()
  a = makeAttribute(tree, "a")
  b = makeAttribute(tree, "b")
  c = makeAttribute(tree, "c")

  setExpression(tree, a, "$$$b$$$", {$$$b$$$: b.id})
  setExpression(tree, b, "$$$c$$$", {$$$c$$$: c.id})
  setExpression(tree, c, "$$$b$$$", {$$$b$$$: b.id})

  expectedCircularReferencePath = [a.bundle, b.bundle, c.bundle, b.bundle]
  expectedError = new BuiltinEnvironment.CircularReferenceError(
    expectedCircularReferencePath)

  t.deepEqual(a.bundle.value(), expectedError, 'value works')
  t.deepEqual(a.bundle.dependencies(), [b.bundle, c.bundle], 'dependencies works')
  t.deepEqual(a.bundle.circularReferencePath(), expectedCircularReferencePath, 'circularReferencePath works')
  t.end()
