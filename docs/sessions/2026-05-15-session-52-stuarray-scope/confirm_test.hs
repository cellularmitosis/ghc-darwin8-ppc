-- Session 52 / iter D: confirm the big-endian bit/byte mismatch
-- diagnosis in STUArray Bool's newArray.
--
-- HYPOTHESIS:
--   newArray (0, sz-1) v :: STUArray Int Bool calls
--   setByteArray# marr# 0# (bOOL_SCALE sz) e# where e# = 0xFF (True)
--   or 0x00 (False).  bOOL_SCALE sz = ceil(sz/8) BYTES.
--
--   But unsafeRead uses readWordArray# which loads SIZEOF_HSWORD bytes
--   (4 on PPC32) starting at the array offset.  On BIG-ENDIAN, the
--   resulting word's bit 0 = LSB = memory byte at offset
--   (WORD_SIZE-1), NOT memory byte 0.
--
--   For sz=8 elements, bOOL_SCALE=1 byte → only memory byte 0 is set.
--   But elements 0..7 of word 0 live in memory byte 3 (BE LSB).
--   So all 8 elements read GARBAGE regardless of initialValue.
--
-- PREDICTIONS to verify on pmacg5 (PPC32 BE):
--   (1) newArray True  sz=8 → expect all True but should see Falses
--       (≈ 50% False rate, since garbage is uniformly random).
--   (2) newArray False sz=24 → expect all False but should see Trues
--       (≈ 50% True rate).
--   (3) newArray False sz=32 → expect all False, clean (whole word zeroed).
--   (4) newArray False sz=33 → element 32 lives in byte 7 of mem
--       (BE LSB of word 1).  bOOL_SCALE 33 = 5 → zeroes bytes 0..4.
--       Byte 7 uninit → element 32 reads garbage.

{-# LANGUAGE BangPatterns #-}
module Main where

import Data.Array.ST
import Control.Monad.ST
import Data.List (foldl')
import System.IO

burnGC :: Int -> Int
burnGC n =
  let xs = [1..n] :: [Int]
      ys = map (* 2) xs
      zs = filter even ys
  in foldl' (+) 0 zs

checkInit :: Bool -> Int -> [Bool]
checkInit initVal n = runST $ do
  arr <- newArray (0, n - 1) initVal :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]

-- Returns list of element indices that disagree with initVal.
diffs :: Bool -> [Bool] -> [Int]
diffs initVal xs = [i | (i, x) <- zip [0..] xs, x /= initVal]

run :: String -> Bool -> Int -> Int -> IO ()
run label initVal sz count = do
  let loop !i !nBad !idxHist
        | i > count = do
            putStrLn (label ++ " init=" ++ show initVal ++ " sz=" ++ show sz
                      ++ " iters=" ++ show count
                      ++ " bad=" ++ show nBad
                      ++ " idxHist=" ++ show (take 16 idxHist))
        | otherwise = do
            let _ = burnGC 1000
                xs = checkInit initVal sz
                _ = burnGC 1000
                ds = diffs initVal xs
            if not (null ds)
              then loop (i + 1) (nBad + 1) (ds ++ idxHist)
              else loop (i + 1) nBad idxHist
  loop 1 0 []
  hFlush stdout

main :: IO ()
main = do
  let count = 2000
  putStrLn ("# Session 52 confirm_test: count=" ++ show count)
  hFlush stdout
  putStrLn "## Prediction (1): newArray True sz=8 should see Falses on BE"
  run "newArray True " True  8  count
  putStrLn "## Prediction (2): newArray False sz=24 should see Trues on BE"
  run "newArray False" False 24 count
  putStrLn "## Prediction (3): newArray False sz=32 should be clean"
  run "newArray False" False 32 count
  putStrLn "## Prediction (4): newArray False sz=33 should fail at index 32+"
  run "newArray False" False 33 count
  putStrLn "## Prediction: newArray False sz=40 should fail at index 32..39 (byte 7)"
  run "newArray False" False 40 count
