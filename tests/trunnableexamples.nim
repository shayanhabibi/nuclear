import nuclear

block nuclear:
  doAssert $(nuclear int) == $(Nuclear[int])

block nuclear_addr:
  var y: int = 5
  var x = nuclearAddr y
  doAssert x[] == 5
  doAssert y == 5

# block nuclear_unsafe_addr:
#   var y: int = 5
#   var x = nuclearUnsafeAddr y
#   doAssert x[] == 5 # fails
#   doAssert y == 5

block nucleate:
  var x = nucleate int
  x[] = 5
  doAssert cast[ptr int](x)[] == 5

block denucleate:
  var x: nuclear int = nucleate int
  denucleate x

block bracket:
  type
    Obj = object
      field1: int
      field2: int
  var x = nucleate Obj
  x[] = Obj(field1: 5, field2: 8)
  doAssert x[] == Obj(field1: 5, field2: 8)
  denucleate x

block bracket_assgn:
  var x = nucleate int
  x[] = 5
  doAssert x[] == 5
  denucleate x

block operator_arrow:
  var x = nucleate int
  var y = nucleate int
  x[] = 5
  y[] = 7
  x <- y
  y[] = 8
  doAssert x[] == 7
  doAssert y[] == 8


block dot_field_access:
  type
    Obj = object
      field1: int
      field2: int

  var x = nucleate Obj # allocate nuclear pointer
  doAssert x[] == Obj(field1: 0, field2: 0)

  # x[].field2 = 5 <- the load will be volatile since the object
  #                   is larger than 8 bytes, and the assignment
  #                   will not be atomic.

  x.field2[] = 5  # atomic assignment

  doAssert x.field2[] == 5
  doAssert x[] == Obj(field1: 0, field2: 5)

  denucleate x