module ZK.Adder (Vellas, circuit) where

import Circuit
import Circuit.Language
import Data.Field.Galois (Prime, PrimeField)
import Data.Vector (fromList, (!))
import Protolude

type Vellas = Prime 28948022309329048855892746252171976963363056481941647379679742748393362948097

circuit :: (Hashable f, PrimeField f) => ExprM f ()
circuit = do
  adder <- var_ <$> fieldInput Private "adder"
  step_in <- for (fromList [0 .. 1]) $ \(i :: Int) -> do
    var_ <$> fieldInput Public ("step_in_" <> show i)
  void $ fieldOutput "step_out_0" $ step_in ! 0 + adder
  void $ fieldOutput "step_out_1" $ step_in ! 0 + step_in ! 1