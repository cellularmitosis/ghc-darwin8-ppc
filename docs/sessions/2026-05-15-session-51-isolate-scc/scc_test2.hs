-- Heavier scc test: allocates large structures around the scc call to
-- increase the chance of GC corruption during the call.

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

-- Allocate (and force) a big garbage list to put pressure on GC.
burnGC :: Int -> Int
burnGC n =
  let xs = [1..n] :: [Int]
      ys = map (* 2) xs
      zs = filter even ys
  in foldl' (+) 0 zs

-- Run scc inside a sequence of allocations.
testInterleaved :: Int -> Int -> IO ()
testInterleaved nGraphSz nReps = do
  let go acc i
        | i > nReps = return acc
        | otherwise = do
            let _ = burnGC 1000              -- garbage
                g = mkNoEdges nGraphSz       -- build a graph
                _ = burnGC 1000              -- more garbage
                f = scc g                    -- the actual call
                _ = burnGC 1000              -- more garbage
                trees = length f
                verts = forestSize f
            if trees /= nGraphSz || verts /= nGraphSz
              then do
                putStrLn $ "BAD at iter " ++ show i ++ ": trees=" ++ show trees
                         ++ " verts=" ++ show verts ++ " (expected " ++ show nGraphSz ++ ")"
                hFlush stdout
                go (acc + 1) (i + 1)
              else go acc (i + 1)
  bad <- go 0 1
  if bad == 0
    then putStrLn $ "OK interleaved nGraph=" ++ show nGraphSz
                  ++ " nReps=" ++ show nReps ++ " bad=0"
    else putStrLn $ "BAD-SUMMARY interleaved nGraph=" ++ show nGraphSz
                  ++ " nReps=" ++ show nReps ++ " bad=" ++ show bad
  hFlush stdout

main :: IO ()
main = do
  testInterleaved 1 1000
  testInterleaved 8 1000
  testInterleaved 8 5000
  testInterleaved 32 1000
  testInterleaved 128 200
