main :: IO ()
main = do
  -- Int overflow
  let top = maxBound :: Int
  putStrLn $ "maxBound Int = " ++ show top
  putStrLn $ "maxBound + 1 = " ++ show (top + 1)
  putStrLn $ "minBound - 1 = " ++ show (minBound - 1 :: Int)
  -- Big Integer
  putStrLn $ "10^50 = " ++ show (10^(50::Int) :: Integer)
  -- Fractional
  putStrLn $ "1.0 / 0 = " ++ show (1.0 / 0 :: Double)
  putStrLn $ "0.0 / 0 = " ++ show (0.0 / 0 :: Double)
  putStrLn $ "-0.0 :: Double = " ++ show (-0.0 :: Double)
  -- isInfinite / isNaN
  putStrLn $ "isInfinite (1/0) = " ++ show (isInfinite (1/0 :: Double))
  putStrLn $ "isNaN (0/0) = " ++ show (isNaN (0/0 :: Double))
