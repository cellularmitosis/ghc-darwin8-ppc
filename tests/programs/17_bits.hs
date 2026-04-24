import Data.Bits
import Data.Word

main :: IO ()
main = do
  let a = 0xFF :: Word32
  let b = 0x0F :: Word32
  putStrLn $ "a = 0x" ++ showHex16 a
  putStrLn $ "b = 0x" ++ showHex16 b
  putStrLn $ "a .&. b = 0x" ++ showHex16 (a .&. b)
  putStrLn $ "a .|. b = 0x" ++ showHex16 (a .|. b)
  putStrLn $ "xor a b = 0x" ++ showHex16 (xor a b)
  putStrLn $ "complement b = 0x" ++ showHex16 (complement b)
  putStrLn $ "shiftL 1 8 = " ++ show ((shiftL (1 :: Word32) 8))
  putStrLn $ "shiftR 256 4 = " ++ show ((shiftR (256 :: Word32) 4))
  putStrLn $ "popCount 0xF0F0 = " ++ show (popCount (0xF0F0 :: Word32))
  where
    showHex16 :: Word32 -> String
    showHex16 x = let s = showsHex x ""
                  in replicate (8 - length s) '0' ++ s
    showsHex = showHexPad

    showHexPad :: Word32 -> ShowS
    showHexPad 0 = ('0':)
    showHexPad n = go n
      where
        go 0 = id
        go k = go (k `shiftR` 4) . (hexDigit (fromIntegral (k .&. 0xF)) :)
        hexDigit c = "0123456789ABCDEF" !! c
