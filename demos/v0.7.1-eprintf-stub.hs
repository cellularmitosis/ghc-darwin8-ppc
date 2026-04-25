-- v0.7.1 — __eprintf stub for ghc-bignum/gmp.  This demo exists
-- because ghc-bignum's loaded `.o` references `___eprintf` (an old
-- gcc helper for `assert()` macros), which Tiger's libSystem has but
-- doesn't *export*.  Pre-v0.7.1, loading bignum via iserv crashed
-- with "unknown symbol `___eprintf'".  Patch 0011 registers a stub
-- in the RTS so the runtime loader can resolve it.
--
-- This demo simply uses a small Integer (which depends on bignum) to
-- prove that libgmp + ghc-bignum + base all link end-to-end on Tiger.
-- Without v0.7.1 changes nothing breaks at *static* link time — the
-- stub is only needed when iserv is loading objects at runtime — but
-- exercising bignum is a useful smoke test that the static path is
-- unaffected by the patch.
--
-- Build + run:
--   scripts/runghc-tiger demos/v0.7.1-eprintf-stub.hs
module Main where

import Data.Char (chr, ord)

main :: IO ()
main = do
  -- Force a libgmp / ghc-bignum codepath by computing a big factorial.
  let f n = product [1..n] :: Integer
  let n = 20
  putStrLn $ show n ++ "! = " ++ show (f n)

  -- Sanity: 21! is bigger than Word64 max, so this exercises the
  -- bignum path even on 32-bit PPC.
  let g = f 21 :: Integer
  putStrLn $ "21! = " ++ show g
  putStrLn $ "21! / 20! = " ++ show (g `div` f n)

  -- A bit of Char arithmetic just to keep base + ghc-prim warm.
  putStrLn $ "char roundtrip: " ++ (chr . ord <$> "Tiger PPC")
