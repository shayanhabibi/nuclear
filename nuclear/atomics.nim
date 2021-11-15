## Atomic operations for nuclears

import nuclear
import nuclear/spec

proc fetchXor*[T](location: nuclear T; value: SomeInteger; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
  cast[T](atomic_fetch_xor_explicit(location.cptr, cast[nonAtomicType(T)](value), order))
proc compareExchange*[T, E](location: nuclear T; expected: var E, desired: T | E; success, failure: MemoryOrder): bool {.inline.} =
  atomic_compare_exchange_strong_explicit(location.cptr, cast[ptr nonAtomicType(E)](addr(expected)), cast[nonAtomicType(T)](desired), success, failure)
proc compareExchange*[T, E](location: nuclear T; expected: var E, desired: T | E; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
  compareExchange(location, expected, desired, order, order)