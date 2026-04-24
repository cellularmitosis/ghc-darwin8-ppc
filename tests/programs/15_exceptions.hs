import Control.Exception

main :: IO ()
main = do
  -- divide-by-zero
  r1 <- try (evaluate (div 10 0)) :: IO (Either ArithException Int)
  putStrLn $ "div 10 0: " ++ show r1
  -- head of empty list
  r2 <- try (evaluate (head ([] :: [Int]))) :: IO (Either ErrorCall Int)
  putStrLn $ "head []: " ++ show r2
  -- custom error
  r3 <- try (evaluate (error "my error")) :: IO (Either ErrorCall Int)
  putStrLn $ "error: " ++ show r3
  -- successful evaluation
  r4 <- try (evaluate (42 `div` 3)) :: IO (Either SomeException Int)
  putStrLn $ "div 42 3: " ++ show r4
  putStrLn "END"
