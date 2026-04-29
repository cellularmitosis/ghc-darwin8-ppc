{-# LANGUAGE DeriveGeneric #-}
import qualified Data.ByteString.Lazy as LB
import Data.Binary
import Data.Word
import GHC.Generics

data MyEnum
  = A Int
  | B Int
  | C Word64
  | D Word64
  | E Int
  deriving (Generic, Show)

instance Binary MyEnum

main :: IO ()
main = do
  let v = C 95110952
  let bs = encode v
  putStrLn $ "encoded C 95110952 size=" ++ show (LB.length bs) ++ " bytes=" ++ show (LB.unpack bs)
  let v2 :: MyEnum
      v2 = decode bs
  putStrLn $ "decoded: " ++ show v2

  -- Now manually craft bytes and decode
  let bs2 = LB.pack [0x02, 0x00, 0x00, 0x00, 0x00, 0x05, 0xAB, 0x47, 0x28]
  putStrLn $ "manual input: " ++ show (LB.unpack bs2)
  let v3 :: MyEnum
      v3 = decode bs2
  putStrLn $ "manual decoded: " ++ show v3
