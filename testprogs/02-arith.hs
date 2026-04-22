-- Integer + Double arithmetic, IO monad, print.
main :: IO ()
main = do
  let i = 6 * 7 :: Int
      d = 22.0 / 7.0 :: Double
      sums = sum [1..100] :: Int
  if i == 42 && abs (d - 3.142857) < 0.001 && sums == 5050
     then putStrLn "OK 02-arith"
     else error ("FAIL 02-arith: " ++ show (i, d, sums))
