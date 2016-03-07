test = require("tape")

Dataflow = require("../src/Dataflow/Dataflow")


test "Values are computed correctly", (t) ->
  a = new Dataflow.Cell -> 4
  b = new Dataflow.Cell -> a.run() * 2
  t.equal(b.run(), 8)
  t.end()

test "Cacheing works", (t) ->
  aCount = 0
  bCount = 0
  cCount = 0
  a = new Dataflow.Cell ->
    aCount++
    return 4
  b = new Dataflow.Cell ->
    bCount++
    return a.run() * 2
  c = new Dataflow.Cell ->
    cCount++
    return b.run() + a.run()
  Dataflow.run ->
    t.equal(a.run(), 4)
    t.equal(b.run(), 8)
    t.equal(c.run(), 12)
    t.equal(aCount, 1)
    t.equal(bCount, 1)
    t.equal(cCount, 1)
  t.end()
