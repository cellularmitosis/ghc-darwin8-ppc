-- Session 52 / iter C: Does the bug correlate with allocation size
-- in BYTES, not with element type?  STUArray Bool with sz=8 allocates
-- 1 byte (bit-packed); STUArray Word8 with sz=1 allocates 1 byte
-- (one byte per element).
--
-- Test:
--   STUArray Bool   at sz=8, 16, 32, 64, 128, 256, 512 elements
--                   → 1, 2, 4, 8, 16, 32, 64 bytes
--   STUArray Word8  at sz=1, 2, 4, 8, 16, 32, 64 bytes
--   STUArray Int    at sz=1, 2, 4, 8, 16, 32, 64 elements (4-256 bytes)

{-# LANGUAGE BangPatterns #-}
module Main where

import Data.Array.ST
import Control.Monad.ST
import Data.Word
import Data.List (foldl')
import System.IO

burnGC :: Int -> Int
burnGC n =
  let xs = [1..n] :: [Int]
      ys = map (* 2) xs
      zs = filter even ys
  in foldl' (+) 0 zs

checkBool :: Int -> [Bool]
checkBool n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]

checkWord8 :: Int -> [Word8]
checkWord8 n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STUArray s Int Word8)
  mapM (readArray arr) [0 .. n - 1]

checkInt :: Int -> [Int]
checkInt n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STUArray s Int Int)
  mapM (readArray arr) [0 .. n - 1]

sweep :: String -> Int -> (Int -> [a]) -> (a -> Bool) -> Int -> IO ()
sweep label sz check bad count = do
  let loop !i !nBad
        | i > count = putStrLn (label ++ " sz=" ++ show sz
                                ++ " iters=" ++ show count
                                ++ " bad=" ++ show nBad)
        | otherwise = do
            let _ = burnGC 1000
                xs = check sz
                _ = burnGC 1000
                badCount = length (filter bad xs)
            if badCount /= 0
              then loop (i + 1) (nBad + 1)
              else loop (i + 1) nBad
  loop 1 0
  hFlush stdout

main :: IO ()
main = do
  let count = 3000
  putStrLn ("# Session 52 size_test: count=" ++ show count)
  hFlush stdout

  -- Bool: bit-packed.  Allocation bytes = ceil(sz/8).
  putStrLn "## STUArray Bool (bit-packed)"
  sweep "STUArray Bool   " 8   checkBool (== True) count  -- 1 byte
  sweep "STUArray Bool   " 16  checkBool (== True) count  -- 2
  sweep "STUArray Bool   " 32  checkBool (== True) count  -- 4
  sweep "STUArray Bool   " 64  checkBool (== True) count  -- 8
  sweep "STUArray Bool   " 128 checkBool (== True) count  -- 16
  sweep "STUArray Bool   " 256 checkBool (== True) count  -- 32
  sweep "STUArray Bool   " 512 checkBool (== True) count  -- 64

  -- Word8: one byte per element.  Allocation bytes = sz.
  putStrLn "## STUArray Word8 (one byte each)"
  sweep "STUArray Word8  " 1   checkWord8 (/= 0) count  -- 1 byte
  sweep "STUArray Word8  " 2   checkWord8 (/= 0) count  -- 2
  sweep "STUArray Word8  " 4   checkWord8 (/= 0) count  -- 4
  sweep "STUArray Word8  " 8   checkWord8 (/= 0) count  -- 8
  sweep "STUArray Word8  " 16  checkWord8 (/= 0) count  -- 16
  sweep "STUArray Word8  " 32  checkWord8 (/= 0) count  -- 32
  sweep "STUArray Word8  " 64  checkWord8 (/= 0) count  -- 64

  -- Int: 4 bytes per element (PPC32).
  putStrLn "## STUArray Int (4 bytes each on PPC32)"
  sweep "STUArray Int    " 1   checkInt (/= 0) count  -- 4 bytes
  sweep "STUArray Int    " 2   checkInt (/= 0) count  -- 8
  sweep "STUArray Int    " 4   checkInt (/= 0) count  -- 16
  sweep "STUArray Int    " 8   checkInt (/= 0) count  -- 32
