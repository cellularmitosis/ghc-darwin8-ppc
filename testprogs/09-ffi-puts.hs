-- FFI: call libSystem `puts` directly.  Exercises the FFI calling
-- convention (Darwin PowerOpen ABI: arg0 in r3) and the RTS adjustor
-- machinery isn't needed for this direction (Haskell -> C); the
-- mirror direction (C -> Haskell callback) isn't tested here.
import Foreign.C.String (newCString)
import Foreign.C.Types  (CInt(..), CChar)
import Foreign.Ptr      (Ptr)

foreign import ccall "puts" c_puts :: Ptr CChar -> IO CInt

main :: IO ()
main = do
  s <- newCString "OK 09-ffi-puts"
  _ <- c_puts s
  return ()
