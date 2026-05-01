{-# LANGUAGE BangPatterns #-}
module Main where

import System.IO.Unsafe (unsafePerformIO)
import Data.IORef
import Control.Monad

-- Simulate GHC's UniqSupply with unsafePerformIO global counter
counter :: IORef Int
counter = unsafePerformIO (newIORef 0)
{-# NOINLINE counter #-}

freshUniq :: Int
freshUniq = unsafePerformIO $ do
  n <- readIORef counter
  writeIORef counter (n + 1)
  return n
{-# NOINLINE freshUniq #-}

-- Generate a list of fresh uniques and force evaluation
go :: Int -> IO [Int]
go n = mapM (\_ -> return $! freshUniq) [1..n]

main :: IO ()
main = do
  xs <- go 10
  putStrLn ("uniques: " ++ show xs)
  -- Run again to see if stateful
  ys <- go 5
  putStrLn ("uniques 2: " ++ show ys)
