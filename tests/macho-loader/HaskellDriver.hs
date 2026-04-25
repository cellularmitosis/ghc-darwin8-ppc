-- Loads Greeter.o at runtime via the RTS linker, looks up symbols,
-- and calls them.  Exercises PPC_RELOC_HA16/LO16/HI16 (the halves
-- of 32-bit addresses emitted by the PPC Haskell code generator).
{-# LANGUAGE ForeignFunctionInterface #-}
module Main where

import Foreign
import Foreign.C
import System.Environment
import System.IO

foreign import ccall "initLinker"    c_initLinker    :: IO ()
foreign import ccall "loadObj"       c_loadObj       :: CString -> IO CInt
foreign import ccall "resolveObjs"   c_resolveObjs   :: IO CInt
foreign import ccall "lookupSymbol"  c_lookupSymbol  :: CString -> IO (Ptr ())

-- The entry points in a Haskell .o are stg_ap_*_ret / <Module>_<fn>_entry.
-- We use the _entry point directly which is an StgFunPtr to a function
-- that takes no explicit args but uses the Haskell calling convention.
-- For simplicity here we don't actually call the entry (that needs a
-- live RTS and a properly initialized Capability + Stack).  Instead we
-- just verify:
--   1. loadObj succeeds (ocVerifyImage + ocGetNames worked)
--   2. resolveObjs succeeds (relocateSectionPPC ran with no barfs)
--   3. lookupSymbol finds the _entry symbols (hash table populated
--      correctly)
-- That already exercises the full reloc surface because relocateSection
-- runs over every section during resolveObjs.

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  args <- getArgs
  case args of
    [objPath] -> go objPath
    _ -> error "usage: haskell-driver <path-to-Greeter.o>"
  where
    go objPath = do
      c_initLinker
      putStrLn "initLinker: ok"
      rc1 <- withCString objPath c_loadObj
      putStrLn $ "loadObj " ++ show objPath ++ " => " ++ show rc1
      if rc1 == 0 then error "loadObj failed" else return ()
      rc2 <- c_resolveObjs
      putStrLn $ "resolveObjs => " ++ show rc2
      if rc2 == 0 then error "resolveObjs failed" else return ()
      -- Probe a couple of symbols (leading underscore per Mach-O convention).
      let probe sym = do
            addr <- withCString sym c_lookupSymbol
            putStrLn $ "lookupSymbol(" ++ sym ++ ") => " ++ show addr
            if addr == nullPtr
              then error (sym ++ " not found")
              else return ()
      probe "_Greeter_haskellAnswer_entry"
      probe "_Greeter_haskellGreet_entry"
      putStrLn "test ok: Haskell .o loaded, resolved, and symbols found"
