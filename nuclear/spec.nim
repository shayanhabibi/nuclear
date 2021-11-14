template volatileLoad*[T](src: ptr T): T =
  ## Generates a volatile load of the value stored in the container `src`.
  ## Note that this only effects code generation on `C` like backends.
  when nimvm:
    src[]
  else:
    when defined(js):
      src[]
    else:
      var res: T
      {.emit: [res, " = (*(", typeof(src[]), " volatile*)", src, ");"].}
      res

template volatileStore*[T](dest: ptr T, val: T) =
  ## Generates a volatile store into the container `dest` of the value
  ## `val`. Note that this only effects code generation on `C` like
  ## backends.
  when nimvm:
    dest[] = val
  else:
    when defined(js):
      dest[] = val
    else:
      {.emit: ["*((", typeof(dest[]), " volatile*)(", dest, ")) = ", val, ";"].}

# Just including the parts of atomics that I care about



{.push, header: "<stdatomic.h>".}

type
  MemoryOrder* {.importc: "memory_order".} = enum
    moRelaxed
    moConsume
    moAcquire
    moRelease
    moAcquireRelease
    moSequentiallyConsistent

type
  AtomicInt8* {.importc: "_Atomic NI8".} = int8
  AtomicInt16* {.importc: "_Atomic NI16".} = int16
  AtomicInt32* {.importc: "_Atomic NI32".} = int32
  AtomicInt64* {.importc: "_Atomic NI64".} = int64

template nonAtomicType*(T: typedesc): untyped =
    # Maps types to integers of the same size
    when sizeof(T) == 1: int8
    elif sizeof(T) == 2: int16
    elif sizeof(T) == 4: int32
    elif sizeof(T) == 8: int64

template atomicType*(T: typedesc): untyped =
  # Maps the size of a trivial type to it's internal atomic type
  when sizeof(T) == 1: AtomicInt8
  elif sizeof(T) == 2: AtomicInt16
  elif sizeof(T) == 4: AtomicInt32
  elif sizeof(T) == 8: AtomicInt64

proc atomic_load_explicit*[T, A](location: ptr A; order: MemoryOrder): T {.importc.}
proc atomic_store_explicit*[T, A](location: ptr A; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.importc.}

when false: # might use these later
  proc atomic_exchange_explicit*[T, A](location: ptr A; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
  proc atomic_compare_exchange_strong_explicit*[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}
  proc atomic_compare_exchange_weak_explicit*[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}

  # Numerical operations
  proc atomic_fetch_add_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
  proc atomic_fetch_sub_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
  proc atomic_fetch_and_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
  proc atomic_fetch_or_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
  proc atomic_fetch_xor_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}

{.pop.}
