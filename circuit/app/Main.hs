module Main where

import Circom.CLI (defaultMain)
import Circuit (Vesta)
import Protolude
import ZK.Adder (circuit)

main :: IO ()
main = defaultMain "adder" (circuit @Vesta)
