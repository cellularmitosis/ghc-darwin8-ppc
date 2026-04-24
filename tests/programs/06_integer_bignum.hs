main :: IO ()
main = do
  let big = 2^100 :: Integer
  putStrLn $ "2^100 = " ++ show big
  let factorial n = product [1..n] :: Integer
  putStrLn $ "20! = " ++ show (factorial 20)
  putStrLn $ "30! = " ++ show (factorial 30)
  putStrLn $ "50! = " ++ show (factorial 50)
  putStrLn $ "2^200 + 1 = " ++ show (2^200 + 1 :: Integer)
  let gcd' = gcd (factorial 10) (factorial 8 * 7)
  putStrLn $ "gcd(10!, 8!*7) = " ++ show gcd'
