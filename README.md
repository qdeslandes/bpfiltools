# bpfiltools

## What is this repository?

`bpfiltools` aims to ease `bpfilter` testing by simplifying the build process for `bpfilter` itself, but also for clients such as `iptables` which doesn't natively support `bpfilter`.

Eventually, tools and scripts from this repository are integrated into the `bpfilter` repository. Most of the tools present here are used during `bpfilter` development, although they should be considered unstable.

## How does it work?

First of all, you will need to clone the following repositories:
- [`bpfilter`](https://github.com/facebook/bpfilter)
- [`iptables`](https://github.com/qdeslandes/iptables): this is a fork of the `iptables` repository. Checkout the `bpfilter` branch to ensure your custom `iptables` binary will support `bpfilter`!

Now, you need to tell `Makefile` where to find `bpfilter` and `iptables` sources, you can either:
- Provide `BF_SRC_DIR` and `IPT_SRC_DIR` as a `make` variable, such as `make bf.build BF_SRC_DIR=${BPFILTER_REPO_PATH} IPT_SRC_DIR=${IPTABLES_REPO_PATH}`.
- Add both `BF_SRC_DIR` and `IPT_SRC_DIR` into `.env` at the root of this repository. The Makefile will include it if available. Keep in mind that `.env` is ignored by Git.

Finally, you can build, test, and run `bpfilter` and `iptables`:
- `bf`: build `bpfilter` and run tests for both 'debug' and 'release' build types.
  - `bf.debug`: build `bpfilter` and run tests only for the 'debug' build type.
  - `bf.release`: build `bpfilter` and run tests only for the 'release' build type.
  - `bf.configure`: configure `bpfilter` (using CMake).
  - `bf.build`: build `bpfilter`
  - `bf.check`: check `bpfilter` coding style, run the unit tests, and the end-to-end tests.
  - `bf.install`: install `bpfilter`.
  - `bf.run`: run `bpfilter` with `--transient` and `--verbose` flags. Use `BF_RUN_FLAGS` to override default flags.
  - `bf.reset`: remove all `bpfilter` artefacts: socket file, serialised context, and pinned BPF programs.
- `ipt`: build `iptables`, and install it.
  - `ipt.fetch`: copy `iptables` sources into the build directory. `iptables` doesn't support out-of-tree build, due to autotools.
  - `ipt.configure`: configure `iptables` (using `autogen.sh` and `./configure`).
  - `ipt.build`: build `iptables`.
  - `ipt.install`: install `iptables`.
- `ci`: clean build artefact, then build `bpfilter` and `iptables` from scratch in 'debug' and 'release' mode, and run checks. Useful to quickly test `bpfilter` and ensure it works as expected (from build to end-to-end tests).
  - `ci.checkout`: checkout `bpfilter` repository to the git reference `CI_BF_REF` and `iptables` repository to the git reference `CI_IPT_REF`. Default values are respectively `origin/main` and `origin/bpfilter`.
- `mrproper`: remove the build folder.

Unless specific otherwise, all targets will build in 'release' mode. You can use `BUILD_TYPE` variable to build in 'debug' mode (with debug symbols and sanitisers):
```shell
make bf BUILD_TYPE=debug
```
