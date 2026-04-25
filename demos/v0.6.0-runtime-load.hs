-- v0.6.0 — PPC Mach-O runtime loader.
--
-- The headline feature of v0.6.0 was *restoring* GHC's runtime
-- object loader for PPC (deleted in commit 374e44704b in Dec 2018).
-- This demo exercises it directly: it asks the RTS to dynamically
-- load a freshly-compiled `.o` file and call a function out of it.
--
-- Companion C source: tests/macho-loader/greeter.c.  Build with:
--   ppc-cc --target=powerpc-apple-darwin -c \
--          tests/macho-loader/greeter.c -o /tmp/greeter.o
-- Then ship the .o + this driver:
--   scripts/runghc-tiger demos/v0.6.0-runtime-load.hs /tmp/greeter.o
--
-- Expected output (last two lines):
--   answer() returned 42
--   relocateSectionPPC: hello from a runtime-loaded .o!
--
-- See tests/macho-loader/run.sh for the full test runner.
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

foreign import ccall "dynamic" mkAnswer :: FunPtr (IO CInt) -> IO CInt
foreign import ccall "dynamic" mkGreet  :: FunPtr (IO ())   -> IO ()

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  [path] <- getArgs
  c_initLinker
  rc1 <- withCString path c_loadObj
  putStrLn $ "loadObj    => " ++ show rc1
  rc2 <- c_resolveObjs
  putStrLn $ "resolveObjs => " ++ show rc2
  ans <- withCString "_answer" c_lookupSymbol >>= mkAnswer . castPtrToFunPtr
  putStrLn $ "answer() returned " ++ show ans
  withCString "_greet" c_lookupSymbol >>= mkGreet . castPtrToFunPtr
