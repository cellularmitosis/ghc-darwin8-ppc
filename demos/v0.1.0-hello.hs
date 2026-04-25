-- The first program ever to compile with this toolchain and run on
-- Tiger PPC.  v0.1.0's headline.  Demonstrates:
--   * cross-compile to Mach-O ppc_7400
--   * libHSrts.a for PPC actually starts up + tears down cleanly
--   * the SSH-bridged final link via Tiger's ld
--
-- Build + run:
--   scripts/runghc-tiger demos/v0.1.0-hello.hs
--   # or, the long form:
--   powerpc-apple-darwin8-ghc demos/v0.1.0-hello.hs -o /tmp/hello
--   scp /tmp/hello $PPC_HOST:/tmp/ && ssh $PPC_HOST /tmp/hello
module Main where

main :: IO ()
main = putStrLn "hello from ppc darwin 8"
