main :: IO ()
main = do
  let a = 42 :: Int
  let b = -17 :: Int
  putStrLn $ "a = " ++ show a
  putStrLn $ "b = " ++ show b
  putStrLn $ "a + b = " ++ show (a + b)
  putStrLn $ "a * b = " ++ show (a * b)
  putStrLn $ "a `div` 3 = " ++ show (a `div` 3)
  putStrLn $ "a `mod` 5 = " ++ show (a `mod` 5)
  putStrLn $ "minBound :: Int = " ++ show (minBound :: Int)
  putStrLn $ "maxBound :: Int = " ++ show (maxBound :: Int)
  putStrLn $ "2^30 :: Int = " ++ show ((2^30) :: Int)
