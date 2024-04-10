# Audit Repository Template

## Getting Started

### Overview

[Kontrol](https://github.com/runtimeverification/kontrol) is a tool by [Runtime Verification](https://runtimeverification.com/) (RV) that enables formal verification of Ethereum smart contracts.

## Development Setup

### Use Kup to install Specific Versions of RV Tools On a Local Box for Development and personal Testing
[kup](https://github.com/runtimeverification/k/blob/master/k-distribution/INSTALL.md)
```
bash <(curl https://kframework.org/install)
kup install k
or 
kup install kevm 
or 
kup install kontrol
```

## Tool Suggestions
When working with RV tools for audits at times requires making custom changes. Check these tools out separately apart from this project. 
Utilize a tool called `git worktree` to work on multiple branches of the same repo at the same time. 

Source Doc Reading for [git worktree](https://git-scm.com/docs/git-worktree)
These repositories will track and test the associated deps main releases and run tests against new releases as they update.

### Further Process and use of this repository is noted [here](./process.md) 

## Reproduce builds locally 
Instructions to install Docker are here: [Docker Install](https://docs.docker.com/engine/install/ubuntu/) 
Do not install Docker Desktop. For businesses it is not free and a violation of their user policy. Be sure to install Docker Engine. 
And then run `./test/scripts/[run-kontrol.sh](./kontrol/scripts/run-kontrol.sh) script` to run the proofs run in CI. For a more detailed explanation of how `run-kontrol.sh` works see below.

## General Usage

Use the [`run-kontrol.sh`](./scripts/run-kontrol.sh) script to runs the proofs in all `*.k.sol` files.

```
./kontrol/scripts/run-kontrol.sh [-h|--help] [container|local|dev] [script|tests]
```

The `run-kontrol.sh` script supports three modes of proof execution:

- `container`: Runs the proofs using the same Docker image used in CI. This is the default execution mode—if no arguments are provided, the proofs will be executed in this mode.
- `local`: Runs the proofs with your local Kontrol install, and enforces that the Kontrol version matches the one used in CI, which is specified in [`versions.json`](./versions.json).
- `dev`: Run the proofs with your local Kontrol install, without enforcing any version in particular. The intended use case is proof development and related matters.

It also supports two methods for specifying which tests to execute:

- `script`: Runs the tests specified in the `test_list` variable
- `tests`: Names of the tests to be executed. `tests` can have two forms:
    - `ContractName.testName`: e.g., `run-kontrol.sh ContractName.test1 ContractName.test2`
    - Empty, executing all the functions starting with `test`, `prove` or `check` present in the defined `out` directory. For instance, `./kontrol/scripts/run-kontrol.sh` will execute all `prove_*` functions in the [test](./test/) directory using the same Docker image as in CI. [Warning: executing a big amount of proofs in parallel is _very_ resource intensive]

For a similar description of the options run `run-kontrol.sh --help`.
