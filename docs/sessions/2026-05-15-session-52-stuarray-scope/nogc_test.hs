-- Session 52 / iter B: does STUArray Bool corrupt WITHOUT burnGC
-- pressure?  If yes, the bug is in newArray/setByteArray# itself.
-- If no, the bug is in GC scavenge.

{-# LANGUAGE BangPatterns #-}
module Main where

import Data.Array.ST
import Control.Monad.ST
import System.IO

checkBool :: Int -> [Bool]
checkBool n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]

main :: IO ()
main = do
  let sz = 8
      count = 10000
  putStrLn ("# Session 52 nogc_test: sz=" ++ show sz
            ++ " count=" ++ show count ++ " (no burnGC)")
  hFlush stdout
  let loop !i !nBad
        | i > count = putStrLn ("nogc done iters=" ++ show count
                                ++ " bad=" ++ show nBad)
        | otherwise = do
            let bools = checkBool sz
                trueCount = length (filter id bools)
            if trueCount /= 0
              then do
                if nBad < 5
                  then putStrLn ("iter=" ++ show i ++ " bools=" ++ show bools)
                  else return ()
                hFlush stdout
                loop (i + 1) (nBad + 1)
              else loop (i + 1) nBad
  loop 1 0
