-- Vector (boxed + unboxed) via the `vector` package.
import qualified Data.Vector as V
import qualified Data.Vector.Unboxed as VU

main :: IO ()
main = do
  let v = V.fromList [1..10] :: V.Vector Int
  print v
  print (V.sum v)
  let v2 = V.map (*2) v
  print v2
  let vu = VU.fromList [1..1000] :: VU.Vector Int
  print (VU.sum vu)
  print (VU.length vu)
  let pairs = V.zip v (V.map (+100) v)
  print pairs
