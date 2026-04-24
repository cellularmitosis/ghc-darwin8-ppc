import Foreign.C.String
import Foreign.C.Types

-- POSIX strlen
foreign import ccall "string.h strlen" c_strlen :: CString -> IO CSize

-- getpid
foreign import ccall "unistd.h getpid" c_getpid :: IO CInt

-- abs
foreign import ccall "stdlib.h abs" c_abs :: CInt -> CInt

main :: IO ()
main = do
  pid <- c_getpid
  putStrLn $ "getpid = " ++ show pid
  withCString "hello ppc world" $ \s -> do
    n <- c_strlen s
    putStrLn $ "strlen('hello ppc world') = " ++ show n
  putStrLn $ "abs(-42) = " ++ show (c_abs (-42))
