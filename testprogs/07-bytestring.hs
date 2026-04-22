-- Data.ByteString.Char8 — exercises the `bytestring` library
-- (pinned-memory primops in the RTS, ForeignPtr machinery).
import qualified Data.ByteString.Char8 as B

main :: IO ()
main = do
  let bs  = B.pack "hello, world"
      n   = B.length bs
      up  = B.map (\c -> if c >= 'a' && c <= 'z'
                            then toEnum (fromEnum c - 32) else c) bs
  if n == 12 && B.unpack up == "HELLO, WORLD"
     then putStrLn "OK 07-bytestring"
     else error ("FAIL 07-bytestring: " ++ show (n, B.unpack up))
