# AlinFoundation dependency

VizCE uses this local copy of
[AlinFoundation](https://github.com/alienator88/AlinFoundation), from the
previously pinned upstream commit
`f61241c2ea1856ef41cbfc965afe9d756121456f`. The upstream MIT license is
preserved in `LICENSE`.

The local patch makes the version parser accept a leading `v` or `V` in
GitHub release tags. Without it, `v3.0.0` is parsed as `0.0.0`, preventing
older installed versions from detecting the update.

Release checks also bypass the local HTTP cache, preventing obsolete
permanent redirects from pointing at a deleted repository. The updater
publishes request failures through `releaseFetchError` for the Updates
tab, preserves earlier release notes on failure, and clears the error
after a successful retry. Only the latest overlapping request can publish
its result. Other upstream behavior is unchanged.

Run the dependency regression tests with `make test-foundation`.
`make test` runs these tests before the application tests. When refreshing
this dependency, preserve these fixes until upstream includes them and
run both test suites.
