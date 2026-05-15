-- Minimal STUArray Bool corruption test.
-- Newly-allocated array should have all False entries; check repeatedly.

{-# LANGUAGE BangPatterns #-}
module Main where

import Data.Array.ST
import Control.Monad.ST
import Data.List (foldl')
import System.IO

-- A fresh STUArray Bool of size n. Returns the list of all reads.
checkFresh :: Int -> [Bool]
checkFresh n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]

burnGC :: Int -> Int
burnGC n =
  let xs = [1..n] :: [Int]
      ys = map (* 2) xs
      zs = filter even ys
  in foldl' (+) 0 zs

main :: IO ()
main = do
  let sz = 8
  let loop !i !nBad
        | i > 10000 = putStrLn ("done iters=" ++ show i ++ " bad=" ++ show nBad)
        | otherwise = do
            let _ = burnGC 1000
                bools = checkFresh sz
                _ = burnGC 1000
                trueCount = length (filter id bools)
            if trueCount /= 0
              then do
                if nBad < 10
                  then putStrLn ("iter=" ++ show i ++ " trueCount=" ++ show trueCount
                              ++ " bools=" ++ show bools)
                  else return ()
                hFlush stdout
                loop (i + 1) (nBad + 1)
              else loop (i + 1) nBad
  loop 1 0
