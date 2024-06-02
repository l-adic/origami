{-# LANGUAGE PatternSynonyms #-}

module ZK.Adder (circuit) where

import Circuit
import Circuit.Language
import Data.Field.Galois (GaloisField)
import Data.Vector.Sized (index, pattern Build, pattern Nil, pattern (:<))
import Protolude

circuit ::
  (Hashable f) =>
  (GaloisField f) =>
  ExprM f ()
circuit = do
  adder <- var_ <$> fieldInput Private "adder"
  step_in <- map var_ <$> fieldInputs @2 Public "step_in"
  let step_out =
        let so0 = (step_in `index` 0) + adder
            so1 = (step_in `index` 0) + (step_in `index` 1)
         in Build (so0 :< so1 :< Nil)
  void $ fieldOutputs "step_out" (bundle_ step_out)
