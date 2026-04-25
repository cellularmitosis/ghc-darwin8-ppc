-- v0.6.1 — load a real Haskell .o via the runtime loader.
--
-- v0.6.0 proved the loader works for hand-compiled C objects.
-- v0.6.1 took it further: a real Haskell .o (HI16/LO16/HA16
-- relocation pairs into __nl_symbol_ptr, scattered SECTDIFF in
-- __eh_frame).  Caught a pre-existing 9.2.8 `resolveImports`
-- bug along the way (used old monolithic-image addressing
-- instead of per-section mmap).
--
-- Build the Haskell .o to load:
--   powerpc-apple-darwin8-ghc -c \
--       tests/macho-loader/Greeter.hs -o /tmp/Greeter.o
-- Then run this driver:
--   scripts/runghc-tiger demos/v0.6.1-haskell-load.hs /tmp/Greeter.o
--
-- Expected:
--   loadObj    => 1
--   resolveObjs => 1
--   _Greeter_haskellAnswer_entry @ 0x...
--   _Greeter_haskellGreet_entry  @ 0x...
--   PASS
--
-- See tests/macho-loader/run-haskell.sh.
{-# LANGUAGE ForeignFunctionInterface #-}
module Main where

import Foreign
import Foreign.C
import System.Environment
import System.IO

foreign import ccall "initLinker"   c_initLinker   :: IO ()
foreign import ccall "loadObj"      c_loadObj      :: CString -> IO CInt
foreign import ccall "resolveObjs"  c_resolveObjs  :: IO CInt
foreign import ccall "lookupSymbol" c_lookupSymbol :: CString -> IO (Ptr ())

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  [path] <- getArgs
  c_initLinker
  rc1 <- withCString path c_loadObj
  putStrLn $ "loadObj    => " ++ show rc1
  rc2 <- c_resolveObjs
  putStrLn $ "resolveObjs => " ++ show rc2
  let probe sym = do
        addr <- withCString sym c_lookupSymbol
        putStrLn $ "  " ++ sym ++ " @ " ++ show addr
        return (addr /= nullPtr)
  ok1 <- probe "_Greeter_haskellAnswer_entry"
  ok2 <- probe "_Greeter_haskellGreet_entry"
  putStrLn $ if ok1 && ok2 then "PASS" else "FAIL"
