import Data.Char
main :: IO ()
main = do
  putStrLn $ "ord 'A' = " ++ show (ord 'A')
  putStrLn $ "chr 97 = " ++ show (chr 97)
  putStrLn $ "toUpper 'x' = " ++ show (toUpper 'x')
  putStrLn $ "toLower 'X' = " ++ show (toLower 'X')
  putStrLn $ "isDigit '5' = " ++ show (isDigit '5')
  putStrLn $ "map toUpper \"hello\" = " ++ map toUpper "hello"
  let s = "powerpc tiger"
  putStrLn $ "length = " ++ show (length s)
  putStrLn $ "reverse = " ++ reverse s
  putStrLn $ "words = " ++ show (words s)
