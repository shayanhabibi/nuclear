## (c) Copyright 2021 Shayan Habibi
## 
## Nuclear Pointers
## ================
## 
## This library emulates the behaviour of volatile pointers without using
## volatiles (where possible); the behaviour of volatile pointers is emulated
## using atomic stores and loads with a relaxed memory order.
## 
## Volatiles are used if the object store/load is larger than 8 bytes. Ideally,
## nuclear should be used to atomically alter the objects fields with a field
## operator.

import std/macros
import nuclear/spec

type
  Nuclear*[T] = distinct ptr T
  
template nuclear*(x: typed): untyped =
  ## This is a short hand for emulating the type declaration of ptrs and refs
  runnableExamples:
    doAssert $(nuclear int) == $(Nuclear[int])
  Nuclear[x]

template cptr*[T](x: nuclear T): ptr T =
  ## Alias for casting back to ptr
  cast[ptr T](x)

proc nuclearAddr*[T](x: var T): nuclear T {.inline.} =
  ## Replicates the addr function, except it will return a `nuclear T`
  ## instead of a std `ptr T`
  runnableExamples:
    var y: int = 5
    var x = nuclearAddr y
    doAssert x[] == 5
    doAssert y == 5
  Nuclear[T](addr x)

# proc nuclearUnsafeAddr*[T](x: T): nuclear T {.inline.} =
#   ## Replicates the unsafeAddr function, except it will return a `nuclear T`
#   runnableExamples:
#     let y: int = 5
#     var x = nuclearUnsafeAddr y
#     doAssert x[] == 5
#     doAssert y == 5
#   Nuclear[T](unsafeAddr x)

proc nucleate*[T](x: typedesc[T], size: int = 1): nuclear T {.inline.} =
  ## Nuclear version of std lib `createShared`
  runnableExamples:
    var x = nucleate int
    x[] = 5
    doAssert cast[ptr int](x)[] == 5

  cast[nuclear T](createShared(T, size))
  
proc denucleate*[T](x: nuclear T) {.inline.} =
  ## Nuclear version of std lib `freeShared`
  runnableExamples:
    var x: nuclear int = nucleate int
    denucleate x
  x.cptr.freeShared()

proc `==`*[T](x, y: nuclear T): bool {.inline.} =
  cast[ptr T](x) == cast[ptr T](y)

proc `[]`*[T](nptr: nuclear T): T {.inline.} =
  ## Dereference the pointer atomically; only if T is less than 8 bytes
  ## In the case that the object type T is larger than 8 bytes and exceeds
  ## atomic assurances, we use volatile operations.
  runnableExamples:
    type
      Obj = object
        field1: int
        field2: int
    var x = nucleate Obj
    x[] = Obj(field1: 5, field2: 8)
    doAssert x[] == Obj(field1: 5, field2: 8)
    denucleate x

  when sizeof(T) <= sizeof(int):
    cast[T](
      atomic_load_explicit[nonAtomicType(T), atomicType(T)](
        cast[ptr atomicType(T)](cast[ptr T](nptr)), moRelaxed
      )
    )
  else:
    volatileLoad(nptr.cptr())

proc `[]=`*[T](x: nuclear T; y: T) {.inline.} =
  ## Assign value `y` to the region pointed by the nuclear pointer atomically.
  ## In the case that the object type T is larger than 8 bytes and exceeds
  ## atomic assurances, we use volatile operations.
  runnableExamples:
    var x = nucleate int
    x[] = 5
    doAssert x[] == 5
    denucleate x
    
  when sizeof(T) <= sizeof(int):
    atomic_store_explicit[nonAtomicType(T), atomicType(T)](
      cast[ptr atomicType(T)](x), cast[nonAtomicType(T)](y), moRelaxed
      )
  else:
    volatileStore(x.cptr(), y)

proc `<-`*[T](x, y: nuclear T) {.inline.} =
  ## Load the value in y atomically and store it in x atomically.
  ## In the case that the object type T is larger than 8 bytes and exceeds
  ## atomic assurances, we use volatile operations.
  runnableExamples:
    var x = nucleate int
    var y = nucleate int
    x[] = 5
    y[] = 7
    x <- y
    y[] = 8
    doAssert x[] == 7
    doAssert y[] == 8
  
  when sizeof(T) <= sizeof(int):
    atomic_store_explicit[nonAtomicType(T), atomicType(T)](
      cast[ptr atomicType(T)](x), y[], moRelaxed
    )
  else:
    volatileStore(x.cptr(), volatileLoad(y.cptr()))

proc `!+`*[T](x: nuclear T, y: int): pointer {.inline.} =
  ## Internal leaked procedure
  cast[pointer](cast[int](x) + y)

proc isNil*[T](x: nuclear T): bool {.inline.} =
  ## Alias for `ptr T` isNil procedure.
  cast[ptr T](x).isNil

{.experimental: "dotOperators".}

# TODO - I just realised I have access to the object type from the get go
# if I just reference T instead of going through the type instantiation yada yada.
# Lord. Ah well. No harm; leave it as a chore.

template `.`*[T](x: nuclear T, field: untyped): untyped =
  ## Allows field access to nuclear pointers of object types. The access of
  ## those fields will also be nuclear in that they enforce atomic operations
  ## of a relaxed order.
  cast[Nuclear[typeof(T().field)]](x !+ T.offsetOf(field))

# macro `.`*[T](x: nuclear T, field: untyped): untyped =
#   ## Allows field access to nuclear pointers of object types. The access of
#   ## those fields will also be nuclear in that they enforce atomic operations
#   ## of a relaxed order.

#   runnableExamples:
#     type
#       Obj = object
#         field1: int
#         field2: int

#     var x = nucleate Obj # allocate nuclear pointer
#     doAssert x[] == Obj(field1: 0, field2: 0)

#     # x[].field2 = 5 <- the load will be volatile since the object
#     #                   is larger than 8 bytes, and the assignment
#     #                   will not be atomic.

#     x.field2[] = 5  # atomic assignment

#     doAssert x.field2[] == 5
#     doAssert x[] == Obj(field1: 0, field2: 5)

#     denucleate x

#   var fieldType: NimNode  # This will be the type of the field if found
#   var offset: int # This determines the offset of the field from the object start

#   template returnError(msg: string): untyped =
#     result = nnkPragma.newTree:
#       ident"error".newColonExpr: newLit(msg)
#     result[0].copyLineInfo(x)
#     return result

#   template checkNuclearType: untyped =
#     # We will make sure that the type of T is something we can access fields of
#     # and support
#     case kind(getTypeImpl(getTypeInst(x)[1])) # gets the type of T
#     of nnkObjectTy: discard # It's an object, all is good; we can continue
#     # of nnkTupleTy: warnUser "Nuclear access for tuples is not yet tested"
#     of nnkTupleTy:  # It's a tuple, it might be fine; we can continue for now
#       returnError "Nuclear access for tuples is not yet supported"
#     of nnkRefTy:  # It's a ref object; this might behave a certain way and needs consideration first.
#       returnError "Nuclear field access for nuclears pointing to ref objects is not yet supported"
#     else: # It's not a supported type; throw an error
#       returnError "This nuclear points to a type that is not an object; cannot do field access"
  
#   checkNuclearType()

#   # Get the field list of T
#   var recList = findChild(getTypeImpl(getTypeInst(x)[1]), it.kind == nnkRecList)
#   # Iterate over the field list identifiers
#   for index, n in recList:
#     case n.kind
#     of nnkIdentDefs:
#       # We've found the correct field when the first child node of the
#       # identifier matches what was given
#       if $field == $n[0]:
#         # Get the offset of the field
#         offset = getOffset(n[0])
#         # Iterate over the remaining child nodes to find the identifier
#         # of the type
#         for index, fieldNode in n[1..^1]:
#           echo fieldNode.treeRepr
#           case fieldNode.kind
#           of nnkIdent, nnkSym:
#             # We will save the type and break the loop
#             fieldType = fieldNode
#             break
#           of nnkBracketExpr:
#             fieldType = fieldNode
#             break
#           else: discard
#     else: discard 
#   # Now we'll make our new AST
#   echo offset
#   echo fieldType.repr
#   result = nnkStmtList.newTree(
#     nnkCast.newTree(  # We want to cast pointer arithmetic into a nuclear
#       nnkBracketExpr.newTree(
#         newIdentNode("Nuclear"),
#         newIdentNode(fieldType.repr) # the nuclear T will be the fieldType of the field
#       ),
#       nnkInfix.newTree(
#         newIdentNode("!+"), # use our pointer arithmetic proc
#         newIdentNode($x), # on our nuclear
#         newLit(offset)  # by the offset of the field
#       )
#     )
#   )
#   # We have now generated a statement that is a nuclear pointer to the
#   # field memory region of the object with its type of the field type.
#   # Normal nuclear operations will therefore apply atomic operations
#   # to that field specifically:
#   # `cast[Nuclear[fieldType]](x !+ offset)`
