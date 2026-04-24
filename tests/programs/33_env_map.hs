-- Environment-to-Map + Map operations (use containers heavily).
import System.Environment
import qualified Data.Map.Strict as M
import Data.List (sort)
import Data.Char (toUpper)

main :: IO ()
main = do
  let pairs = [("HOME", "/home/u"), ("PATH", "/usr/bin:/bin"),
               ("USER", "alice"), ("SHELL", "/bin/bash")]
  let m = M.fromList pairs
  putStrLn $ "size = " ++ show (M.size m)
  putStrLn $ "sorted keys:"
  mapM_ putStrLn (M.keys m)
  -- map values to uppercase
  let m2 = M.map (map toUpper) m
  putStrLn "uppercased:"
  mapM_ (\(k,v) -> putStrLn (k ++ " => " ++ v)) (M.toAscList m2)
  -- filter
  let m3 = M.filter (\v -> length v > 5) m
  putStrLn $ "values with length > 5: " ++ show (M.size m3)
  mapM_ putStrLn (sort (M.elems m3))
