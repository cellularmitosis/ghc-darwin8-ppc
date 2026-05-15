-- Minimal repro for Data.Graph.scc miscompute on PPC32 unreg.
-- Expected: prints "OK <N>" for each test where N is the count.
-- Buggy:    prints "BAD ..." with mismatched counts.

module Main where

import Data.Graph
import Data.Array
import System.IO

-- | Build a graph with N vertices and NO edges.
-- All N vertices should be their own SCC: scc returns N trees.
mkNoEdges :: Int -> Graph
mkNoEdges n = listArray (0, n - 1) (replicate n [])

-- | Build a graph with N vertices, each pointing to the next mod N.
-- That's one big cycle, so scc returns exactly 1 tree of N vertices.
mkCycle :: Int -> Graph
mkCycle n = listArray (0, n - 1) [[(i + 1) `mod` n] | i <- [0 .. n - 1]]

-- | Total vertex count across a forest (sum of all tree sizes).
forestSize :: Forest a -> Int
forestSize = sum . map treeSize
  where treeSize (Node _ ts) = 1 + forestSize ts

check :: String -> Int -> Int -> Graph -> IO ()
check name expectedTrees expectedVerts g = do
  let result = scc g
      trees = length result
      verts = forestSize result
  if trees == expectedTrees && verts == expectedVerts
    then putStrLn $ "OK " ++ name ++ " trees=" ++ show trees ++ " verts=" ++ show verts
    else putStrLn $ "BAD " ++ name ++ " trees=" ++ show trees
                  ++ " (expected " ++ show expectedTrees ++ ")"
                  ++ " verts=" ++ show verts
                  ++ " (expected " ++ show expectedVerts ++ ")"
  hFlush stdout

main :: IO ()
main = do
  -- Single-vertex graphs (the dramatic case from session 50: scc returned []).
  check "1-vertex-no-edges"  1 1 (mkNoEdges 1)
  -- 2 vertices, no edges.
  check "2-vertex-no-edges"  2 2 (mkNoEdges 2)
  -- 4 vertices, no edges.
  check "4-vertex-no-edges"  4 4 (mkNoEdges 4)
  -- 8 vertices, no edges (matches Big2.hs's pattern: 8 independent bindings).
  check "8-vertex-no-edges"  8 8 (mkNoEdges 8)
  -- 8 vertices in one cycle: 1 SCC with 8 vertices.
  check "8-vertex-cycle"     1 8 (mkCycle 8)
  -- Larger no-edges graphs (force more allocation / GC).
  check "32-vertex-no-edges" 32 32 (mkNoEdges 32)
  check "128-vertex-no-edges" 128 128 (mkNoEdges 128)
  -- Repeat the 8-vertex test 100 times — should always give the same answer.
  let loopBad =
        [ (i, length (scc (mkNoEdges 8)))
        | i <- [1 .. 100 :: Int]
        , length (scc (mkNoEdges 8)) /= 8 ]
  if null loopBad
    then putStrLn "OK loop100 8-vertex-no-edges all=8"
    else putStrLn $ "BAD loop100 8-vertex-no-edges first-fail="
                  ++ show (head loopBad) ++ " (of "
                  ++ show (length loopBad) ++ " bad)"
  hFlush stdout
