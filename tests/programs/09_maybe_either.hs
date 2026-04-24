safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv x y = Just (x `div` y)

parseNum :: String -> Either String Int
parseNum s = case reads s :: [(Int, String)] of
  [(n, "")] -> Right n
  _         -> Left ("not a number: " ++ s)

main :: IO ()
main = do
  print (safeDiv 10 2)
  print (safeDiv 10 0)
  print (fmap (+1) (Just 5) :: Maybe Int)
  print (fmap (+1) Nothing :: Maybe Int)
  print (parseNum "42")
  print (parseNum "abc")
  case safeDiv 100 7 of
    Just q -> putStrLn $ "100/7 quotient = " ++ show q
    Nothing -> putStrLn "no"
