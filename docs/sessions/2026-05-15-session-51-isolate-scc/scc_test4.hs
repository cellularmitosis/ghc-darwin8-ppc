-- scc with inlined implementation + probes, to localize the bug.
--
-- Replicates Data.Graph.scc from containers, with hooks at each step.

{-# LANGUAGE BangPatterns #-}
module Main where

import Data.Array
import Data.Array.ST
import Data.Array.Unboxed (UArray)
import Control.Monad.ST
import Data.List (foldl')
import System.IO
import Data.IORef
import System.IO.Unsafe (unsafePerformIO)

-- Graph types (mirroring Data.Graph).
type Vertex = Int
type Bounds = (Vertex, Vertex)
type Graph  = Array Vertex [Vertex]
data Tree a = Node { rootLabel :: a, subForest :: Forest a }
type Forest a = [Tree a]

----------------------------------------------------------------------
-- Probes
----------------------------------------------------------------------

{-# NOINLINE probeCounter #-}
probeCounter :: IORef Int
probeCounter = unsafePerformIO (newIORef 0)

probeLog :: String -> Int -> ()
probeLog site n = unsafePerformIO $ do
    k <- atomicModifyIORef' probeCounter (\c -> (c+1, c+1))
    hPutStrLn stderr $ unwords
      [ "PROBE51"
      , "evt=" ++ show k
      , "site=" ++ site
      , "n=" ++ show n
      ]
    hFlush stderr

----------------------------------------------------------------------
-- Inlined scc / dfs / generate / prune / chop / postOrd / transposeG
-- (Same algorithm as Data.Graph in containers.)
----------------------------------------------------------------------

buildG :: Bounds -> [(Vertex, Vertex)] -> Graph
buildG bnds edges = accumArray (flip (:)) [] bnds edges

vertices :: Graph -> [Vertex]
vertices g = indices g

edges :: Graph -> [(Vertex, Vertex)]
edges g = [(v, w) | v <- vertices g, w <- g ! v]

reverseE :: Graph -> [(Vertex, Vertex)]
reverseE g = [(w, v) | (v, w) <- edges g]

transposeG :: Graph -> Graph
transposeG g = buildG (bounds g) (reverseE g)

dff :: Graph -> Forest Vertex
dff g = dfs g (vertices g)

dfs :: Graph -> [Vertex] -> Forest Vertex
dfs g vs =
  let !_p1 = probeLog "dfs_vs_in" (length vs)
      !generated = map (generate g) vs
      !_p2 = probeLog "dfs_generated_len" (length generated)
      !pruned = prune (bounds g) generated
      !_p3 = probeLog "dfs_pruned_len" (length pruned)
  in pruned

generate :: Graph -> Vertex -> Tree Vertex
generate g v = Node v (map (generate g) (g ! v))

prune :: Bounds -> Forest Vertex -> Forest Vertex
prune bnds ts =
  let !_p4 = probeLog "prune_in_len" (length ts)
      !result = runST $ do
        marks <- newArray bnds False :: ST s (STUArray s Vertex Bool)
        chopST marks ts
      !_p5 = probeLog "prune_out_len" (length result)
  in result

chopST :: STUArray s Vertex Bool -> Forest Vertex -> ST s (Forest Vertex)
chopST _ [] = return []
chopST marks (Node v ts : us) = do
  visited <- readArray marks v
  if visited
    then chopST marks us
    else do
      writeArray marks v True
      as <- chopST marks ts
      bs <- chopST marks us
      return (Node v as : bs)

postorder :: Tree a -> [a] -> [a]
postorder (Node a ts) = postorderF ts . (a :)

postorderF :: Forest a -> [a] -> [a]
postorderF ts = foldr (.) id (map postorder ts)

postOrd :: Graph -> [Vertex]
postOrd g = postorderF (dff g) []

scc :: Graph -> Forest Vertex
scc g =
  let !_p6 = probeLog "scc_postOrd_len" (length po)
      po = postOrd (transposeG g)
      !rpo = reverse po
      !_p7 = probeLog "scc_reverse_postOrd_len" (length rpo)
      !result = dfs g rpo
      !_p8 = probeLog "scc_result_len" (length result)
  in result

----------------------------------------------------------------------
-- Test driver
----------------------------------------------------------------------

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

main :: IO ()
main = do
  -- Run a few iterations, one with full trace, then loop to find a bad one
  -- and dump it.
  let g = mkNoEdges 8
  -- A few traced iterations to establish baseline.
  putStrLn "=== iter 1 (full trace) ==="
  hFlush stdout
  let _ = burnGC 1000
      f1 = scc g
      _ = burnGC 1000
  putStrLn $ "iter 1 trees=" ++ show (length f1)
  hFlush stdout

  putStrLn "=== iter 2 ==="
  hFlush stdout
  let _ = burnGC 1000
      f2 = scc g
      _ = burnGC 1000
  putStrLn $ "iter 2 trees=" ++ show (length f2)
  hFlush stdout

  -- Now loop silently until we find a bad one, then trace it.
  let loop !i
        | i > 5000 = putStrLn ("no bad found in " ++ show i ++ " iters")
        | otherwise = do
            let _ = burnGC 1000
                f = scc g
                _ = burnGC 1000
                n = length f
            if n /= 8
              then do
                putStrLn ("=== first bad at iter " ++ show i
                         ++ " trees=" ++ show n ++ " ===")
                hFlush stdout
              else loop (i + 1)
  putStrLn "=== silent loop ==="
  hFlush stdout
  loop 3
  hFlush stdout
