module Main (main) where

import Circom.R1CS (witnessFromCircomWitness)
import Circom.Solver (CircomProgram (..), mkCircomProgram, nativeGenWitness)
import Circuit
import Circuit.Language
import Data.Map qualified as Map
import Protolude
import R1CS (Witness (..))
import Test.Hspec
import Test.QuickCheck
import ZK.Adder (circuit)

main :: IO ()
main = hspec $ do
  let BuilderState {bsVars, bsCircuit} = snd $ runCircuitBuilder (circuit @Vesta)
      program = mkCircomProgram bsVars bsCircuit
      vars = cpVars program
  describe "Circuit" $ do
    it "should accept valid assignments" $
      property $
        \a si0 si1 ->
          let inputs =
                Map.fromList
                  [ ("adder", Simple a),
                    ("step_in", Array [si0, si1])
                  ]
              Witness w =
                witnessFromCircomWitness $
                  nativeGenWitness program inputs
           in lookupArrayVars vars "step_out" w === Just [a + si0, si1 + si0]
    it "should reject invalid assignments" $
      property $
        \a si0 si1 so0 so1 ->
          (so0 /= si0 + a && so1 /= si1 + si0) ==>
            let inputs =
                  Map.fromList
                    [ ("adder", Simple a),
                      ("step_in", Array [si0, si1])
                    ]
                Witness w =
                  witnessFromCircomWitness $
                    nativeGenWitness program inputs
             in lookupArrayVars vars "step_out" w /= Just [so0, so1]
