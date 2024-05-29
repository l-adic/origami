module Main where

import Circom.CLI (defaultMain)
import Protolude
import ZK.Adder (Vesta, circuit)

main :: IO ()
main = defaultMain "adder" (circuit @Vesta)
