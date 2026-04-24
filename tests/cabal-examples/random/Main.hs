-- Seeded RNG via `random` package.  Output is deterministic for
-- seed=42, so this is testable.
import System.Random

main :: IO ()
main = do
  let g = mkStdGen 42
      (x, _) = randomR (1, 100 :: Int) g
  putStrLn $ "random int 1..100 with seed 42: " ++ show x
