{-# LANGUAGE TemplateHaskell #-}
-- v0.8.0 demo: Template Haskell on PowerPC Mac OS X 10.4 Tiger.
--
-- The host (arm64 macOS) GHC compiles this file with -fexternal-interpreter,
-- which spawns ghc-iserv on the Tiger box via scripts/pgmi-shim.sh.  iserv
-- evaluates the splice expressions BELOW (literal-construction TH), sends
-- the resulting AST back, and host GHC stitches them into the output binary.
--
-- For the runtime path:
--   * patch 0009: PPC Mach-O runtime loader (so iserv can loadObj base.o)
--   * patch 0010: enable cross-build of iserv + libiserv
--   * patch 0011: __eprintf stub for ghc-bignum closures
--   * patch 0012 + 0009 expand: BR24 jump-island fix for large .o's
--   * patch 0013: cross-built `binary` library Generic-derived sum tags
--   * patch 0014: byte-swap BCO array contents on endian mismatch
--
-- Build & run:
--   $ source scripts/cross-env.sh
--   $ STAGE1=external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
--   $ $STAGE1 -fexternal-interpreter \
--       -pgmi=$PWD/scripts/pgmi-shim.sh \
--       demos/v0.8.0-th-splice.hs -o /tmp/th-demo
--   $ scp /tmp/th-demo pmacg5:/tmp/ && ssh pmacg5 /tmp/th-demo
--   Hello from a TH splice on Tiger PPC!
--   answer = 42
--   compileTime = "April 29 2026"
--   2 + 3 = 5

module Main where

import Language.Haskell.TH

-- A TH splice that returns a string literal.
greeting :: String
greeting = $(stringE "Hello from a TH splice on Tiger PPC!")

-- A TH splice that returns an Int literal.  Forces the iserv interpreter
-- to deserialize a `Int -> Q Exp` and evaluate it on Tiger.
answer :: Int
answer = $(litE (integerL 42))

-- A TH splice that names a date the day of compilation
-- (literal, not a runtime call — runs on Tiger at compile time).
compileTime :: String
compileTime = $(stringE "April 29 2026")

-- A TH splice that does a small arithmetic at compile time, on Tiger.
plus :: Int
plus = $(litE (integerL (2 + 3)))

main :: IO ()
main = do
  putStrLn greeting
  putStrLn $ "answer = " ++ show answer
  putStrLn $ "compileTime = " ++ show compileTime
  putStrLn $ "2 + 3 = " ++ show plus
