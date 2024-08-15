type
  int128 {.importc: "__int128".} = object
    `✀`, `✂` : uint64 # These fields are inaccessible; to do so
                        # would cause invalid cgen code
  hint128* = object
    x*,y*: uint

  DCas* = int128 | hint128


{.push, header: "<stdatomic.h>".}

type
  MemoryOrder* {.importc: "memory_order".} = enum
    moRelaxed
    moConsume
    moAcquire
    moRelease
    moAcqRel
    moSeqCst

type
  AtomicInt8* {.importc: "_Atomic NI8".} = int8
  AtomicInt16* {.importc: "_Atomic NI16".} = int16
  AtomicInt32* {.importc: "_Atomic NI32".} = int32
  AtomicInt64* {.importc: "_Atomic NI64".} = int64
  AtomicInt128* {.importc: "_Atomic __int128".} = hint128

  Trivial* = SomeNumber | ptr | pointer | int128 | hint128

template trivialType*(T: typedesc): untyped =
  when sizeof(T) == 1: int8
  elif sizeof(T) == 2: int16
  elif sizeof(T) == 4: int32
  elif sizeof(T) == 8: int64
  elif sizeof(T) == 16: int128

template atomicType*(T: typedesc): untyped =
  # Maps the size of a trivial type to it's internal atomic type
  when sizeof(T) == 1: AtomicInt8
  elif sizeof(T) == 2: AtomicInt16
  elif sizeof(T) == 4: AtomicInt32
  elif sizeof(T) == 8: AtomicInt64
  elif sizeof(T) == 16: AtomicInt128

proc signalFence*(order: MemoryOrder) {.importc: "atomic_signal_fence".}
proc fence*(order: MemoryOrder) {.importc: "atomic_thread_fence".}

when defined(gcc):
  # Because GCC will not use the built-in atomic operations
  # for 128 bit integers, we must use the __sync functions
  # when performing 'atomic' operations on 128 bit integers.
  # Therefor atomic operations are overloaded for DCas types
  # before pointing procedures which accept all types to the
  # appropriate atomic operation.

  proc atomic_load_explicit*[T, A: not DCas](location: ptr A; order: MemoryOrder): T {.importc.}
  proc atomic_store_explicit*[T, A: not DCas](location: ptr A; desired: T; order: MemoryOrder = moSeqCst) {.importc.}

  proc atomic_exchange_explicit*[T, A: not DCas](location: ptr A; desired: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_compare_exchange_strong_explicit*[T, A: not DCas](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}
  proc atomic_compare_exchange_weak_explicit*[T, A: not DCas](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}

  # Numerical operations
  proc atomic_fetch_add_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_sub_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_and_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_or_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_xor_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}

  proc atomic_add_fetch_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_sub_fetch_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_and_fetch_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_or_fetch_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_xor_fetch_explicit*[T, A: not DCas](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}

  {.pop.}

  proc syncAddAndFetch*[T](p: ptr T; v: T): T {.importc: "__sync_add_and_fetch", nodecl.}
  proc syncSubAndFetch*[T](p: ptr T; v: T): T {.importc: "__sync_sub_and_fetch", nodecl.}
  proc syncOrAndFetch*[T](p: ptr T; v: T): T {.importc: "__sync_or_and_fetch", nodecl.}
  proc syncAndAndFetch*[T](p: ptr T; v: T): T {.importc: "__sync_and_and_fetch", nodecl.}
  proc syncXorAndFetch*[T](p: ptr T; v: T): T {.importc: "__sync_xor_and_fetch", nodecl.}
  proc syncNandAndFetch*[T](p: ptr T; v: T): T {.importc: "__sync_nand_and_fetch", nodecl.}

  proc syncFetchAndAdd*[T](p: ptr T; v: T): T {.importc: "__sync_fetch_and_add", nodecl.}
  proc syncFetchAndSub*[T](p: ptr T; v: T): T {.importc: "__sync_fetch_and_sub", nodecl.}
  proc syncFetchAndOr*[T](p: ptr T; v: T): T {.importc: "__sync_fetch_and_or", nodecl.}
  proc syncFetchAndAnd*[T](p: ptr T; v: T): T {.importc: "__sync_fetch_and_and", nodecl.}
  proc syncFetchAndXor*[T](p: ptr T; v: T): T {.importc: "__sync_fetch_and_xor", nodecl.}
  proc syncFetchAndNand*[T](p: ptr T; v: T): T {.importc: "__sync_fetch_and_nand", nodecl.}

  proc syncBoolCompareAndSwap*[T](p: ptr T; old, repl: T): bool {.importc: "__sync_bool_compare_and_swap", nodecl.}
  proc syncValCompareAndSwap*[T](p: ptr T; old, repl: T): T {.importc: "__sync_val_compare_and_swap", nodecl.}

  proc syncSynchronize*() {.importc: "__sync_synchronize", nodecl.}

  when defined(x86_64):
    # https://stackoverflow.com/a/25652664
    # We can roll atomic load and store with less cost
    # using this syncCompiler directive
    proc syncCompiler* {.inline.} = {.emit: """asm volatile ("" ::: "memory");""".}
  else:
    proc syncCompiler* {.inline.} = syncSynchronize()

  proc atomic_load_explicit*[T: DCas](location: ptr T; order: static MemoryOrder): T {.inline.} =
    when defined(handRolledLoad):
      syncCompiler()
      copyMem(location, addr result, sizeof(T))
      syncCompiler()
    else:
      cast[T](syncFetchAndAdd(toPtrInt128 location, cast[int128](~[0,0])))
  proc atomic_store_explicit*[T, A: DCas](location: ptr A; value: sink T; order: static MemoryOrder) {.inline.} =
    syncCompiler()
    moveMem(location, addr value , sizeof(T))
    when order in [moRelease, moRelaxed]:
      syncCompiler() # moRelease
    else:
      syncSynchronize() # moSeqCst

  proc atomic_exchange_explicit*[T, A: DCas](location: ptr A; desired: sink T; order: static MemoryOrder): T {.inline.} =
    when defined(handRolledExchange):
      syncCompiler()
      moveMem(addr result, location, sizeof(T))
      moveMem(location, addr desired, sizeof(T))
      syncSynchronize()
    else:
      result = cast[T](location[])
      while not syncBoolCompareAndSwap(location, result, desired):
        result = cast[T](location[])

  proc atomic_compare_exchange_strong_explicit*[T, A: DCas](
      location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder
    ): bool {.inline.} =
    syncBoolCompareAndSwap(location, expected[], desired)
  proc atomic_compare_exchange_weak_explicit*[T, A: DCas](
      location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder
    ): bool {.inline.} =
    syncBoolCompareAndSwap(location, expected[], desired)
  proc atomic_fetch_add_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncFetchAndAdd[T](location, value)
  proc atomic_fetch_sub_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncFetchAndSub(location, value)
  proc atomic_fetch_and_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncFetchAndAnd(location, value)
  proc atomic_fetch_or_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncFetchAndOr(location, value)
  proc atomic_fetch_xor_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncFetchAndXor(location, value)
  proc atomic_add_fetch_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncAddAndFetch(location, value)
  proc atomic_sub_fetch_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncSubAndFetch(location, value)
  proc atomic_and_fetch_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncAndAndFetch(location, value)
  proc atomic_or_fetch_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncOrAndFetch(location, value)
  proc atomic_xor_fetch_explicit*[T, A: DCas](location: ptr A; value: T; order: MemoryOrder): T {.inline.} =
    syncXorAndFetch(location, value)

elif defined(clang):
  proc atomic_load_explicit*[T, A](location: ptr A; order: MemoryOrder): T {.importc.}
  proc atomic_store_explicit*[T, A](location: ptr A; desired: T; order: MemoryOrder = moSeqCst) {.importc.}

  proc atomic_exchange_explicit*[T, A](location: ptr A; desired: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_compare_exchange_strong_explicit*[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}
  proc atomic_compare_exchange_weak_explicit*[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}

  # Numerical operations
  proc atomic_fetch_add_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_sub_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_and_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_or_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_fetch_xor_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}

  proc atomic_add_fetch_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_sub_fetch_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_and_fetch_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_or_fetch_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  proc atomic_xor_fetch_explicit*[T, A](location: ptr A; value: T; order: MemoryOrder = moSeqCst): T {.importc.}
  {.pop.}
