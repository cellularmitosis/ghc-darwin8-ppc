-- scc_test5: drill INSIDE prune/chop to find the exact step that fails.
-- Strategy: only emit probe events after we've observed at least one bad
-- iteration. That way the log is clean noise-free.

{-# LANGUAGE BangPatterns #-}
module Main where

import Data.Array
import Data.Array.ST
import Control.Monad.ST
import Data.List (foldl')
import System.IO
import Data.IORef
import System.IO.Unsafe (unsafePerformIO)

type Vertex = Int
type Bounds = (Vertex, Vertex)
type Graph  = Array Vertex [Vertex]
data Tree a = Node { rootLabel :: a, subForest :: Forest a }
type Forest a = [Tree a]

----------------------------------------------------------------------
-- Probes (only fire when verbose = True)
----------------------------------------------------------------------

{-# NOINLINE probeVerbose #-}
probeVerbose :: IORef Bool
probeVerbose = unsafePerformIO (newIORef False)

{-# NOINLINE probeCounter #-}
probeCounter :: IORef Int
probeCounter = unsafePerformIO (newIORef 0)

probeOn :: IO ()
probeOn = writeIORef probeVerbose True

probeOff :: IO ()
probeOff = writeIORef probeVerbose False

probeIsOn :: () -> Bool
probeIsOn () = unsafePerformIO (readIORef probeVerbose)

probeLog :: String -> Int -> ()
probeLog site n
  | probeIsOn () = unsafePerformIO $ do
      k <- atomicModifyIORef' probeCounter (\c -> (c+1, c+1))
      hPutStrLn stderr $ unwords
        [ "PROBE51"
        , "evt=" ++ show k
        , "site=" ++ site
        , "n=" ++ show n
        ]
      hFlush stderr
  | otherwise = ()

probeLogPair :: String -> Int -> Int -> ()
probeLogPair site a b
  | probeIsOn () = unsafePerformIO $ do
      k <- atomicModifyIORef' probeCounter (\c -> (c+1, c+1))
      hPutStrLn stderr $ unwords
        [ "PROBE51"
        , "evt=" ++ show k
        , "site=" ++ site
        , "a=" ++ show a
        , "b=" ++ show b
        ]
      hFlush stderr
  | otherwise = ()

----------------------------------------------------------------------
-- scc / dfs / prune with probes
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
dfs g vs = prune (bounds g) (map (generate g) vs)

generate :: Graph -> Vertex -> Tree Vertex
generate g v = Node v (map (generate g) (g ! v))

prune :: Bounds -> Forest Vertex -> Forest Vertex
prune bnds ts = runST $ do
  marks <- newArray bnds False :: ST s (STUArray s Vertex Bool)
  let !_p_in = probeLog "prune_chop_in_len" (length ts)
  result <- chopST marks ts 0
  let !_p_out = probeLog "prune_chop_out_len" (length result)
  return result

chopST :: STUArray s Vertex Bool -> Forest Vertex -> Int -> ST s (Forest Vertex)
chopST _ [] !depth = do
  let !_p = probeLogPair "chop_base" depth 0
  return []
chopST marks (Node v ts : us) !depth = do
  visited <- readArray marks v
  let !_p_visit = probeLogPair (if visited then "chop_visited" else "chop_fresh") v depth
  if visited
    then chopST marks us depth
    else do
      writeArray marks v True
      as <- chopST marks ts (depth + 1)
      bs <- chopST marks us depth
      return (Node v as : bs)

postorder :: Tree a -> [a] -> [a]
postorder (Node a ts) = postorderF ts . (a :)

postorderF :: Forest a -> [a] -> [a]
postorderF ts = foldr (.) id (map postorder ts)

postOrd :: Graph -> [Vertex]
postOrd g = postorderF (dff g) []

scc :: Graph -> Forest Vertex
scc g = dfs g (reverse (postOrd (transposeG g)))

----------------------------------------------------------------------
-- Test driver
----------------------------------------------------------------------

mkNoEdges :: Int -> Graph
mkNoEdges n = listArray (0, n - 1) (replicate n [])

burnGC :: Int -> Int
burnGC n =
  let xs = [1..n] :: [Int]
      ys = map (* 2) xs
      zs = filter even ys
  in foldl' (+) 0 zs

main :: IO ()
main = do
  let g = mkNoEdges 8
  let loop !i
        | i > 10000 = putStrLn ("no bad in " ++ show i)
        | otherwise = do
            let _ = burnGC 1000
                f = scc g
                _ = burnGC 1000
                n = length f
            if n /= 8
              then do
                putStrLn ("=== bad at iter " ++ show i
                         ++ " trees=" ++ show n
                         ++ " (replaying with probes on) ===")
                probeOn
                -- Replay with probes
                let !_ = burnGC 1000
                    !f' = scc g
                    !_ = burnGC 1000
                    !n' = length f'
                probeOff
                putStrLn ("replay result trees=" ++ show n')
              else loop (i + 1)
  loop 1
  hFlush stdout
