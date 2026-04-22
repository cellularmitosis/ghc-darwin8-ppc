-- 64-bit integer ops on a 32-bit target.  Exercises the GPR-pair
-- lowering rules in PPC/CodeGen.hs (mul, div, shift, compare).
import Data.Int  (Int64)
import Data.Word (Word64)

main :: IO ()
main = do
  let a = 0x123456789abcdef0 :: Int64
      b = 0x0fedcba987654321 :: Int64
      sum64    = a + b
      prod64   = a * 2
      shr32    = a `div` (2^32)
      cmp      = a > b
      wraps    = (maxBound :: Word64) + 1
  if sum64 == 0x2222222222222211
       && prod64 == 0x2468acf13579bde0
       && shr32  == 0x12345678
       && cmp
       && wraps == 0
     then putStrLn "OK 03-int64"
     else error ("FAIL 03-int64: " ++ show (sum64, prod64, shr32, cmp, wraps))
