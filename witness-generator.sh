#!/bin/bash

cabal run adder -- solve \
  --inputs circom_input.json \
  --witness circom_witness.wtns \
  --encoding decimal-string
