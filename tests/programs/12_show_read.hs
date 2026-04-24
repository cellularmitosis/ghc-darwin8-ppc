data Point = Point Int Int deriving (Show, Read, Eq)

main :: IO ()
main = do
  let p = Point 3 4
  putStrLn $ "show p = " ++ show p
  let p' = read "Point 10 20" :: Point
  putStrLn $ "read 'Point 10 20' = " ++ show p'
  putStrLn $ "equal? " ++ show (Point 10 20 == p')
  -- Read/Show round trip
  let q = Point 7 8
  let s = show q
  let q' = read s :: Point
  putStrLn $ "round trip equal? " ++ show (q == q')
  -- Reading numbers
  print (read "42" :: Int)
  print (read "[1,2,3]" :: [Int])
