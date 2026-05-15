-- Session 52 / iter A: confirm scope of STUArray corruption.
-- For each of: STUArray Bool, Int8, Word8, Int, Word, Char, Word32,
-- and boxed STArray Int, do a `newArray` with the zero value and
-- read back all elements.  Count iterations where any element is
-- not the initial value.
--
-- Same harness as session-51 stuarray_test.hs (burnGC 1000 before
-- and after, 5000 iterations per type for speed).

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main where

import Data.Array.ST
import Control.Monad.ST
import Data.Int
import Data.Word
import Data.List (foldl')
import System.IO

burnGC :: Int -> Int
burnGC n =
  let xs = [1..n] :: [Int]
      ys = map (* 2) xs
      zs = filter even ys
  in foldl' (+) 0 zs

-- For each type, return a list of all reads on a fresh array of size n.
checkBool :: Int -> [Bool]
checkBool n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]

checkInt8 :: Int -> [Int8]
checkInt8 n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STUArray s Int Int8)
  mapM (readArray arr) [0 .. n - 1]

checkWord8 :: Int -> [Word8]
checkWord8 n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STUArray s Int Word8)
  mapM (readArray arr) [0 .. n - 1]

checkInt :: Int -> [Int]
checkInt n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STUArray s Int Int)
  mapM (readArray arr) [0 .. n - 1]

checkWord :: Int -> [Word]
checkWord n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STUArray s Int Word)
  mapM (readArray arr) [0 .. n - 1]

checkChar :: Int -> [Char]
checkChar n = runST $ do
  arr <- newArray (0, n - 1) '\0' :: ST s (STUArray s Int Char)
  mapM (readArray arr) [0 .. n - 1]

checkWord32 :: Int -> [Word32]
checkWord32 n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STUArray s Int Word32)
  mapM (readArray arr) [0 .. n - 1]

-- Boxed STArray Int.  Should NOT corrupt — bug should be byte-array specific.
checkBoxedInt :: Int -> [Int]
checkBoxedInt n = runST $ do
  arr <- newArray (0, n - 1) 0 :: ST s (STArray s Int Int)
  mapM (readArray arr) [0 .. n - 1]

-- A driver: run `count` iterations, calling `check` each time after
-- burnGC, classify result with `bad`, report counts.
sweep :: String -> Int -> (Int -> [a]) -> (a -> Bool) -> Int -> IO ()
sweep label sz check bad count = do
  let loop !i !nBad !firstFew
        | i > count = putStrLn (label ++ " iters=" ++ show count
                                ++ " bad=" ++ show nBad
                                ++ " firstFew=" ++ show (reverse firstFew))
        | otherwise = do
            let _ = burnGC 1000
                xs = check sz
                _ = burnGC 1000
                badCount = length (filter bad xs)
            if badCount /= 0
              then do
                let firstFew' = if length firstFew < 3
                                  then (i, badCount) : firstFew
                                  else firstFew
                hFlush stdout
                loop (i + 1) (nBad + 1) firstFew'
              else loop (i + 1) nBad firstFew
  loop 1 0 []
  hFlush stdout

main :: IO ()
main = do
  let sz = 8
      count = 5000
  putStrLn ("# Session 52 types_test: sz=" ++ show sz
            ++ " count=" ++ show count)
  hFlush stdout
  sweep "STUArray Bool   " sz checkBool (== True) count
  sweep "STUArray Int8   " sz checkInt8 (/= 0) count
  sweep "STUArray Word8  " sz checkWord8 (/= 0) count
  sweep "STUArray Int    " sz checkInt (/= 0) count
  sweep "STUArray Word   " sz checkWord (/= 0) count
  sweep "STUArray Char   " sz checkChar (/= '\0') count
  sweep "STUArray Word32 " sz checkWord32 (/= 0) count
  sweep "STArray  Int    " sz checkBoxedInt (/= 0) count
