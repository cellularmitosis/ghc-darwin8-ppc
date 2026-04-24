import Data.Typeable

data MyType = MyType Int String deriving (Typeable, Show)

main :: IO ()
main = do
  let x = MyType 42 "hello"
  print (typeOf x)
  print (typeOf (42 :: Int))
  print (typeOf "string")
  print (typeOf [1,2,3 :: Int])
  print (typeOf (Just True))
  print (typeOf (Left "err" :: Either String Int))
  -- typeRep comparison
  putStrLn $ "Int == Int: " ++ show (typeRep (Proxy :: Proxy Int) == typeRep (Proxy :: Proxy Int))
  putStrLn $ "Int == Bool: " ++ show (typeRep (Proxy :: Proxy Int) == typeRep (Proxy :: Proxy Bool))
