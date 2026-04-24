main :: IO ()
main = do
  -- Infinite list, take a finite prefix
  let nats = [1..] :: [Int]
  print (take 10 nats)
  -- Lazy evaluation — undefined not touched
  let xs = [1, 2, 3, undefined, 5] :: [Int]
  print (take 3 xs)
  -- head of infinite
  let ones = repeat 1 :: [Int]
  print (take 5 ones)
  -- cycle
  print (take 10 (cycle [1,2,3] :: [Int]))
  -- iterate
  print (take 8 (iterate (*2) 1 :: [Int]))
  -- Lazy folds
  let count = length [1..1000000 :: Int]
  putStrLn $ "length [1..1000000] = " ++ show count
