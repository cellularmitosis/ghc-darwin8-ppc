-- v0.7.2 — large `.o` files (e.g. base.o, ~3 MB) load via iserv.
--
-- The fix was a per-section symbol_extras placement (jump islands
-- inside the RX segment's mmap so they always stay within ±32 MB
-- of every text section).  Pre-v0.7.2, loading base.o tripped
-- "BR24 jump island also out of range".
--
-- This demo loads HSbase-4.16.4.0.o through the runtime linker —
-- the program that broke pre-v0.7.2.  It uses the path the bindist
-- normally has on disk; override with a path on the command line.
--
-- Build + run:
--   scripts/runghc-tiger demos/v0.7.2-large-load.hs \
--       /opt/ghc-ppc/lib/ppc-osx-ghc-9.2.8/base-4.16.4.0/HSbase-4.16.4.0.o
--
-- Expected (last few lines):
--   loadObj    => 1
--   resolveObjs => 1   ← the BR24 fix is what makes this print 1
--   PASS — base.o loaded, resolved, and ready
{-# LANGUAGE ForeignFunctionInterface #-}
module Main where

import Foreign
import Foreign.C
import System.Environment
import System.IO

foreign import ccall "initLinker"   c_initLinker   :: IO ()
foreign import ccall "loadObj"      c_loadObj      :: CString -> IO CInt
foreign import ccall "resolveObjs"  c_resolveObjs  :: IO CInt

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  args <- getArgs
  let path = case args of
        (p:_) -> p
        _     -> "/opt/ghc-ppc/lib/ppc-osx-ghc-9.2.8/base-4.16.4.0/HSbase-4.16.4.0.o"
  putStrLn $ "Loading " ++ path
  c_initLinker
  rc1 <- withCString path c_loadObj
  putStrLn $ "loadObj    => " ++ show rc1
  rc2 <- c_resolveObjs
  putStrLn $ "resolveObjs => " ++ show rc2
  if rc1 == 1 && rc2 == 1
    then putStrLn "PASS — base.o loaded, resolved, and ready"
    else putStrLn "FAIL"
