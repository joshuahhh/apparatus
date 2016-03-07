test = require "tape"
Model = require "../src/Model/Model"
Attribute = Model.Attribute
ExpressionAttribute = Model.ExpressionAttribute
InternalAttribute = Model.InternalAttribute



test "Numbers work", (t) ->
  a = ExpressionAttribute.createVariant()
  a.setExpression("6")
  console.log(a.value())
  t.deepEqual(a.value().toArray(), [6])
  t.end()

test "Math expressions work", (t) ->
  a = ExpressionAttribute.createVariant()
  a.setExpression("5 + 5")
  t.deepEqual(a.value().toArray(), [10])
  t.end()

test "References work", (t) ->
  a = ExpressionAttribute.createVariant()
  b = ExpressionAttribute.createVariant()

  a.setExpression("20")
  b.setExpression("$$$a$$$ * 2", {$$$a$$$: a})

  t.deepEqual(b.value().toArray(), [40])
  t.end()

test "Changes recompile", (t) ->
  a = ExpressionAttribute.createVariant()
  b = ExpressionAttribute.createVariant()

  a.setExpression("20")
  b.setExpression("$$$a$$$ * 2", {$$$a$$$: a})

  t.deepEqual(b.value().toArray(), [40])

  a.setExpression("10")
  t.deepEqual(b.value().toArray(), [20])

  b.setExpression("$$$a$$$ * 3", {$$$a$$$: a})
  t.deepEqual(b.value().toArray(), [30])
  t.end()

test "Dependencies work", (t) ->
  a = ExpressionAttribute.createVariant({label: "a"})
  b = ExpressionAttribute.createVariant({label: "b"})
  c = ExpressionAttribute.createVariant({label: "c"})

  a.setExpression("$$$b$$$ * 2", {$$$b$$$: b})
  b.setExpression("$$$c$$$ * 3", {$$$c$$$: c})
  c.setExpression("20")

  t.deepEqual(a.value().toArray(), [120])
  t.deepEqual(a.dependencies(), [b, c], "dependencies works")
  t.deepEqual(a.circularReferencePath(), null, "circularReferencePath works")
  t.end()

test "Dependencies work with circular references", (t) ->
  a = ExpressionAttribute.createVariant({label: "a"})
  b = ExpressionAttribute.createVariant({label: "b"})
  c = ExpressionAttribute.createVariant({label: "c"})

  a.setExpression("$$$b$$$", {$$$b$$$: b})
  b.setExpression("$$$c$$$", {$$$c$$$: c})
  c.setExpression("$$$b$$$", {$$$b$$$: b})

  expectedCircularReferencePath = [a, b, c, b]
  expectedError = new Attribute.CircularReferenceError(
    expectedCircularReferencePath)

  t.deepEqual(a.value(), expectedError, "value works")
  t.deepEqual(a.dependencies(), [b, c], "dependencies works")
  t.deepEqual(a.circularReferencePath(), expectedCircularReferencePath, "circularReferencePath works")
  t.end()

test "Attributes based on internal functions work", (t) ->
    a = ExpressionAttribute.createVariant()
    a.setExpression("1 + 1")

    b = InternalAttribute.createVariant
      internalFunction: (referenceValues) -> referenceValues.$$$a$$$ + 1
    b.setReferences({$$$a$$$: a})

    t.deepEqual(b.value().toArray(), [3])
    t.end()
