# AlinFoundation dependency

VizCE uses this local copy of
[AlinFoundation](https://github.com/alienator88/AlinFoundation), from the
previously pinned upstream commit
`f61241c2ea1856ef41cbfc965afe9d756121456f`. The upstream MIT license is
preserved in `LICENSE`.

The local patch makes the version parser accept a leading `v` or `V` in
GitHub release tags. Without it, `v3.0.0` is parsed as `0.0.0`, preventing
older installed versions from detecting the update. All other upstream
source is unchanged.

Run the dependency regression tests with `make test-foundation`.
`make test` runs these tests before the application tests. When refreshing
this dependency, preserve the parser fix until upstream includes it and
run both test suites.
