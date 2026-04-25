-- v0.3.0 — one-command install.  This demo does NOT require building
-- from source: it should run straight off a freshly installed
-- bindist.  Demonstrates the bindist tarball is self-contained and
-- runnable, and that getEnv / getExecutablePath / FilePath all work.
--
-- Install:
--   tar xJf ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz
--   cd ghc-9.2.8-powerpc-apple-darwin8
--   ./install.sh --prefix=$PREFIX --ppc-host=$YOUR_TIGER
--
-- Build + run:
--   scripts/runghc-tiger demos/v0.3.0-self-locate.hs
module Main where

import System.Environment (getExecutablePath, getProgName, getArgs)
import System.IO (hFlush, stdout)

main :: IO ()
main = do
  prog <- getProgName
  exe  <- getExecutablePath
  args <- getArgs
  putStrLn $ "name : " ++ prog
  putStrLn $ "exe  : " ++ exe
  putStrLn $ "args : " ++ show args
  hFlush stdout
