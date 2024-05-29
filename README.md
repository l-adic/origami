# Origami

This repo demonstrates an integration of the l-adic circuit DSL with the [nova](https://github.com/microsoft/Nova) folding scheme. The integration is made possible by the existing cirom integration [nova-scotia](https://github.com/nalinbhardwaj/Nova-Scotia).

The example circuit is a simple adding circuit which is taken from the `nova-scotia` toy example. You can compare the two versions:

- [circom](https://github.com/nalinbhardwaj/Nova-Scotia/blob/main/examples/toy/toy.circom)

- [l-adic](https://github.com/l-adic/origami/blob/main/circuit/src/ZK/Adder.hs)


## Build Instructions
```
> cabal build all
> cargo build
```

## Test Instructions
```
> cabal test all
```

## Run Instructions
```
> cabal run adder -- compile
> cargo run
```