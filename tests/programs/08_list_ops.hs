import Data.List
main :: IO ()
main = do
  let xs = [5, 2, 8, 1, 9, 3, 7, 4, 6] :: [Int]
  putStrLn $ "xs = " ++ show xs
  putStrLn $ "sort xs = " ++ show (sort xs)
  putStrLn $ "reverse xs = " ++ show (reverse xs)
  putStrLn $ "sum xs = " ++ show (sum xs)
  putStrLn $ "product xs = " ++ show (product xs)
  putStrLn $ "take 3 (sort xs) = " ++ show (take 3 (sort xs))
  putStrLn $ "map (*2) xs = " ++ show (map (*2) xs)
  putStrLn $ "filter even xs = " ++ show (filter even xs)
  putStrLn $ "foldr (+) 0 xs = " ++ show (foldr (+) 0 xs)
  putStrLn $ "zip [1..] \"abc\" = " ++ show (zip [(1::Int)..] "abc")
  putStrLn $ "[1..10] = " ++ show [(1::Int)..10]
