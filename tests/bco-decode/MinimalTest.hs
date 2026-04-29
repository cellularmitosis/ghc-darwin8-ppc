{-# LANGUAGE ScopedTypeVariables #-}
import qualified Data.ByteString.Lazy as LB
import Data.Binary
import Data.Binary.Get
import GHCi.ResolvedBCO

main :: IO ()
main = do
  -- Construct a hand-crafted byte stream that should decode as
  -- ResolvedBCOStaticPtr (RemotePtr 0x05AB4728):
  --   tag = 2 (Word8)
  --   field = Word64 BE = 0x0000000005AB4728
  let bs = LB.pack [0x02, 0x00, 0x00, 0x00, 0x00, 0x05, 0xAB, 0x47, 0x28]
  putStrLn $ "input bytes: " ++ show (LB.unpack bs) ++ " (length " ++ show (LB.length bs) ++ ")"
  let p :: ResolvedBCOPtr
      p = runGet get bs
  putStrLn $ "decoded: " ++ show p
