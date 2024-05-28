{-# LANGUAGE  PatternSynonyms #-}
module ZK.Adder (Vellas, circuit) where

import Circuit
import Circuit.Language
import Data.Field.Galois (Prime, PrimeField)
import Data.Vector.Sized (index, pattern Build, pattern (:<), pattern Nil)
import Protolude

type Vellas = Prime 28948022309329048855892746252171976963363056481941647379679742748393362948097

circuit :: (Hashable f, PrimeField f) => ExprM f ()
circuit = do
  adder <- var_ <$> fieldInput Private "adder"
  step_in <- map var_ <$> fieldInputs @2 Public "step_in"
  let step_out = bundle_ $ Build (
        step_in `index` 0 + adder :< 
        step_in `index` 0 + step_in `index` 1 :<
        Nil)
  void $ fieldOutputs "step_out" step_out