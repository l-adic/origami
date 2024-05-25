module Main where

import Circom.CLI (defaultMain)
import Protolude
import ZK.Adder (Vellas, circuit)

main :: IO ()
main = defaultMain "adder" (circuit @Vellas)
