-- Sweep graph sizes to map the bug's size sensitivity.

module Main where

import Data.Graph
import Data.Array
import Data.List (foldl')
import System.IO

mkNoEdges :: Int -> Graph
mkNoEdges n = listArray (0, n - 1) (replicate n [])

forestSize :: Forest a -> Int
forestSize = sum . map treeSize
  where treeSize (Node _ ts) = 1 + forestSize ts

burnGC :: Int -> Int
burnGC n =
  let xs = [1..n] :: [Int]
      ys = map (* 2) xs
      zs = filter even ys
  in foldl' (+) 0 zs

testInterleaved :: Int -> Int -> IO ()
testInterleaved nGraphSz nReps = do
  let go !acc !i
        | i > nReps = return acc
        | otherwise = do
            let _ = burnGC 1000
                g = mkNoEdges nGraphSz
                _ = burnGC 1000
                f = scc g
                _ = burnGC 1000
                trees = length f
            if trees /= nGraphSz
              then go (acc + 1) (i + 1)
              else go acc (i + 1)
  bad <- go 0 1
  putStrLn $ "size=" ++ show nGraphSz ++ " reps=" ++ show nReps
           ++ " bad=" ++ show bad
  hFlush stdout

main :: IO ()
main = mapM_ (\n -> testInterleaved n 500) [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 24, 28, 32, 48, 64, 96, 128, 256]
