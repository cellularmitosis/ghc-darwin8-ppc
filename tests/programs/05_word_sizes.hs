import Data.Word
import Data.Int

main :: IO ()
main = do
  putStrLn $ "Word8  max = " ++ show (maxBound :: Word8)
  putStrLn $ "Word16 max = " ++ show (maxBound :: Word16)
  putStrLn $ "Word32 max = " ++ show (maxBound :: Word32)
  putStrLn $ "Word64 max = " ++ show (maxBound :: Word64)
  putStrLn $ "Int8   max = " ++ show (maxBound :: Int8)
  putStrLn $ "Int16  max = " ++ show (maxBound :: Int16)
  putStrLn $ "Int32  max = " ++ show (maxBound :: Int32)
  putStrLn $ "Int64  max = " ++ show (maxBound :: Int64)
  putStrLn $ "Int8   min = " ++ show (minBound :: Int8)
