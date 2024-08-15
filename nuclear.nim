## (c) Copyright 2021-2024 Shayan Habibi
##
## Nuclear Atomics
## ================
##
## Employs std atomic operations with additional
## support for 16 byte types.
## Provides types hint128 which converts internally
## to int128 for atomic operations

## GCC does not necessarily compile the proper instruction set
## for 16 byte atomic operations even on x86_64 despite archi-
## -tectural support.
## This is borne due to intel being willing to provide assurance
## of supporting instructions while AMD did not. GCC therefore
## does not compile the appropriate instruction set for AMD
## processors (if it does for even intel is not known to me).
##
## Some wizards have found that the only way to get GCC to compile
## the correct instruction set in modern iterations is to use the
## __sync legacy functions. These come at a higher cost.
##
## The alternative is to use CLANG, which is what the authors of
## research for 'Crystalline' and 'Hyaline' did.
##
## For potential compatability with GCC, and other architectures,
## __sync funcs are used for 128bit ops.

import nuclear/spec {.all.}

export hint128, MemoryOrder

proc `$`*(x: hint128): string = $ cast[array[2,uint]](x)
proc `$`*(x: int128): string {.used.} = $ cast[hint128](x)
template `~`*(x: array[2, uint|int]): hint128 = cast[hint128](x)

type
  Nuclear*[T] = object
    when sizeof(T) == 1: value: AtomicInt8
    elif sizeof(T) == 2: value: AtomicInt16
    elif sizeof(T) == 4: value: AtomicInt32
    elif sizeof(T) == 8: value: AtomicInt64
    elif sizeof(T) == 16: value: AtomicInt128

template `@`[T: Trivial](x: ptr T): untyped =
  cast[ptr trivialType typeof x[]](x)
template `@`[T](x: ptr Nuclear[T]): untyped =
  cast[typeof x[].value.addr](x)

# ============= PTR PROCS ============= #
# These ptr procs are unnecessary since they should inherently accepted by
# var procs. However, they are included due to a suspicious series of
# errors I was getting before, that may have been unrelated. Will test further.

proc load*[T](p: ptr Nuclear[T]; order: static MemoryOrder = moSeqCst): T =
  cast[T]( atomic_load_explicit[T](@p, order) )

proc store*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst) {.inline.} =
  atomic_store_explicit(@p, v, order)

proc exchange*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_exchange_explicit[T](@p, v, order) )

proc compareExchange*[T](p: ptr Nuclear[T]; expected: ptr T; desired: T; success, failure: static MemoryOrder): bool {.inline.} =
  atomic_compare_exchange_strong_explicit(@p, @expected, desired, success, failure)

proc compareExchange*[T](p: ptr Nuclear[T]; expected: ptr T; desired: T; order: static MemoryOrder = moSeqCst): bool {.inline.} =
  compareExchange(p, expected, desired, order, order)

proc compareExchangeWeak*[T](p: ptr Nuclear[T]; expected: ptr T; desired: T; success, failure: static MemoryOrder): bool {.inline.} =
  atomic_compare_exchange_weak_explicit(@p, @expected, desired, success, failure)

proc compareExchangeWeak*[T](p: ptr Nuclear[T]; expected: ptr T; desired: T; order: static MemoryOrder = moSeqCst): bool {.inline.} =
  compareExchangeWeak(p, expected, desired, order, order)

proc fetchAdd*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_fetch_add_explicit[T](@p, v, order) )

proc fetchSub*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_fetch_sub_explicit[T](@p, v, order) )

proc fetchAnd*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_fetch_and_explicit[T](@p, v, order) )

proc fetchOr*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_fetch_or_explicit[T](@p, v, order) )

proc fetchXor*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_fetch_xor_explicit[T](@p, v, order) )

proc addFetch*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_add_fetch_explicit[T](@p, v, order) )

proc subFetch*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_sub_fetch_explicit[T](@p, v, order) )

proc andFetch*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_and_fetch_explicit[T](@p, v, order) )

proc orFetch*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_or_fetch_explicit[T](@p, v, order) )

proc xorFetch*[T](p: ptr Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  cast[T]( atomic_xor_fetch_explicit[T](@p, v, order) )

# ============= VAR PROCS ============= #

proc load*[T](
    p: var Nuclear[T]; order: static MemoryOrder = moSeqCst
    ): T {.inline.} =
  load(addr p, order)

proc store*[T](
    p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst
    ) {.inline.} =
  store(addr p, v, order)

proc exchange*[T](
    p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst
    ): T {.inline.} =
  exchange(addr p, v, order)

proc compareExchange*[T](
    p: var Nuclear[T]; expected: var T; desired: T;
    success, failure: static MemoryOrder
    ): bool {.inline.} =
  compareExchange(addr p, addr expected, desired, success, failure)

proc compareExchange*[T](
    p: var Nuclear[T]; expected: var T; desired: T;
    order: static MemoryOrder = moSeqCst
    ): bool {.inline.} =
  compareExchange(addr p, addr expected, desired, order)

proc compareExchangeWeak*[T](
    p: var Nuclear[T]; expected: var T; desired: T;
    success, failure: static MemoryOrder
    ): bool {.inline.} =
  compareExchangeWeak(addr p, addr expected, desired, success, failure)

proc compareExchangeWeak*[T](
    p: var Nuclear[T]; expected: var T; desired: T;
    order: static MemoryOrder = moSeqCst
    ): bool {.inline.} =
  compareExchangeWeak(addr p, addr expected, desired, order)

proc fetchAdd*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  fetchAdd(addr p, v, order)

proc fetchSub*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  fetchSub(addr p, v, order)

proc fetchAnd*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  fetchAnd(addr p, v, order)

proc fetchOr*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  fetchOr(addr p, v, order)

proc fetchXor*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  fetchXor(addr p, v, order)

proc addFetch*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  addFetch(addr p, v, order)

proc subFetch*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  subFetch(addr p, v, order)

proc andFetch*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  andFetch(addr p, v, order)

proc orFetch*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  orFetch(addr p, v, order)

proc xorFetch*[T](p: var Nuclear[T]; v: T; order: static MemoryOrder = moSeqCst): T {.inline.} =
  xorFetch(addr p, v, order)

