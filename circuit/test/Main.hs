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
import ZK.Adder (Vellas, circuit)

main :: IO ()
main = hspec $ do
  let BuilderState {bsVars, bsCircuit} = snd $ runCircuitBuilder (circuit @Vellas)
      program = mkCircomProgram bsVars bsCircuit
      vars = cpVars program
  describe "Circuit" $ do
    it "should accept valid assignments" $
      property $
        \a si0 si1 ->
          let inputs =
                Map.fromList
                  [ ("adder", a),
                    ("step_in_0", si0),
                    ("step_in_1", si1)
                  ]
              Witness w =
                witnessFromCircomWitness $
                  nativeGenWitness program inputs
           in (lookupVar vars "step_out_0" w === Just (a + si0))
                .&&. (lookupVar vars "step_out_1" w === Just (si1 + si0))
    it "should reject invalid assignments" $
      property $
        \a si0 si1 so0 so1 ->
          (so0 /= si0 + a && so1 /= si1 + si0)
            ==> let inputs =
                      Map.fromList
                        [ ("adder", a),
                          ("step_in_0", si0),
                          ("step_in_1", si1)
                        ]
                    Witness w =
                      witnessFromCircomWitness $
                        nativeGenWitness program inputs
                 in (lookupVar vars "step_out_0" w /= Just so0)
                      .&&. (lookupVar vars "step_out_1" w /= Just so1)