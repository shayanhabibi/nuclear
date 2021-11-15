## Atomic operations for nuclears

import nuclear
import nuclear/spec

proc fetchXor*[T](location: nuclear T; value: SomeInteger; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
  cast[T](atomic_fetch_xor_explicit(location.cptr, cast[nonAtomicType(T)](value), order))
proc compareExchange*[T](location: Nuclear[Nuclear[T]] | ptr Nuclear[T]; expected: var Nuclear[T] | var ptr T, desired: Nuclear[T] | ptr T; success, failure: MemoryOrder): bool {.inline.} =
  atomic_compare_exchange_strong_explicit(cast[ptr nonAtomicType(pointer)](cast[ptr Nuclear[T]](location)), cast[ptr nonAtomicType(pointer)](expected.unsafeaddr), cast[nonAtomicType(pointer)](desired), success, failure)
proc compareExchange*[T](location: Nuclear[Nuclear[T]] | ptr Nuclear[T]; expected: var Nuclear[T] | var ptr T, desired: Nuclear[T]| ptr T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
  compareExchange(location, expected, desired, order, order)