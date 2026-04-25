-- v0.2.0 — pi is 3.14 again.
--
-- v0.1.0 had a codegen bug: `pi :: Double` returned 8.6e97 because
-- 32-bit unregisterised `decomposeMultiWord` in CmmToC didn't recurse
-- on `CmmFloat n W64`, leaving a static Double closure laid out as
-- (con-info + truncated-32-bit) instead of (con-info + hi32 + lo32).
-- Patch 0008 fixes the recursion.  pi now prints correctly.
--
-- Bug write-up: docs/sessions/2026-04-24-session-1-workflow-and-pi-probe/
-- The fix:      patches/0008-cmmtoc-split-w64-double-on-32bit.patch
--
-- Build + run:
--   scripts/runghc-tiger demos/v0.2.0-pi.hs
module Main where

main :: IO ()
main = do
  putStrLn $ "pi      = " ++ show (pi :: Double)
  putStrLn $ "exp 1   = " ++ show (exp 1   :: Double)
  putStrLn $ "sqrt 2  = " ++ show (sqrt 2  :: Double)
  -- Just for sanity.  Without patch 0008 the first line would read
  -- something like "pi      = 8.609132365004017e97".
