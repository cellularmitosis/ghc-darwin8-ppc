-- Long-running allocation + GC pressure: allocate 10^6 small
-- records via a fold, compute their sum.  Exercises minor + major GC.
-- Use Int64 explicitly so the expected 3,500,003,500,000 fits on both
-- 32-bit and 64-bit targets.
import Data.List (foldl')
import Data.Int (Int64)

data Rec = Rec !Int64 !Int64

sumRecs :: Int -> Int64
sumRecs n = snd $ foldl' step (0, 0) [1..fromIntegral n]
  where
    step (!acc_x, !acc_y) i =
      let !r = Rec (i * 3) (i * 7)
          !nx = case r of Rec x _ -> acc_x + x
          !ny = case r of Rec _ y -> acc_y + y
      in (nx, ny)

main :: IO ()
main = do
  let n = 1000000 :: Int
  let result = sumRecs n
  putStrLn $ "summed " ++ show n ++ " records"
  putStrLn $ "sum = " ++ show result
  -- Known good: sum [1..10^6] * 7 = 500000500000 * 7 = 3500003500000
  let expected = sum [1..fromIntegral n] * 7 :: Int64
  putStrLn $ "expected (sum [1..n] * 7) = " ++ show expected
  putStrLn $ "match: " ++ show (result == expected)
