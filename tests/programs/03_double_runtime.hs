main :: IO ()
main = do
  let x = fromIntegral (3 :: Int) :: Double
  let y = fromIntegral (5 :: Int) :: Double
  putStrLn $ "x = " ++ show x
  putStrLn $ "y = " ++ show y
  putStrLn $ "sqrt 2 = " ++ show (sqrt 2 :: Double)
  putStrLn $ "sqrt 4 = " ++ show (sqrt 4 :: Double)
  putStrLn $ "sin 0 = " ++ show (sin 0 :: Double)
  putStrLn $ "exp 1 = " ++ show (exp 1 :: Double)
  putStrLn $ "log 10 = " ++ show (log 10 :: Double)
