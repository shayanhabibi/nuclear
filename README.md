# Nuclear

Simple library that implements something that behaves along the lines of a volatile pointer.

This is **not** volatile pointers however; nuclear pointers have appropriate cache memory coherence that is suitable for multi-threading which volatile pointers in C and C++ do not necessarily guarantee (different in java and C#).

## Why use it

Allows you to allocate a object and not have to be concerned with assigning values to fields not being seen by other threads.

This is primarily useful for lock-free algorithms, as will be used in my TSLQueue implementation.

## Under the hood

It's not difficult or anything special, we use atomic loads and stores without enforcing any sequential ordering (relaxed memory order).

## Documentation

[The full API documentation is generated from the source and is kept up-to-date on GitHub.](https://shayanhabibi.github.io/nuclear/nuclear.html)
