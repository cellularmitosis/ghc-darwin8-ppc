-- Data.Map.Strict — exercises the `containers` library, which lives
-- separately from base and validates that we have the boot libraries
-- linked correctly.
import qualified Data.Map.Strict as M

main :: IO ()
main = do
  let m = foldr (\k -> M.insert k (k * k)) M.empty [1..50 :: Int]
      v = M.lookup 25 m
      sz = M.size m
  if v == Just 625 && sz == 50
     then putStrLn "OK 06-data-map"
     else error ("FAIL 06-data-map: " ++ show (v, sz))
