{-# LANGUAGE BangPatterns #-}
module Main where

import Data.IORef
import Control.Monad

-- Simulate GHC's UniqSupply by an IORef Int

newSupply :: Int -> IO (IORef Int)
newSupply = newIORef

nextUnique :: IORef Int -> IO Int
nextUnique r = do
  !n <- readIORef r
  writeIORef r (n + 1)
  return n

mkName :: IORef Int -> String -> IO (String, Int)
mkName supply nm = do
  u <- nextUnique supply
  return (nm, u)

-- Mimic a Bag-style traversal building a list of named items, using a monadic action that
-- reads/writes IORef state.
data Bag a = EmptyBag | UnitBag a | TwoBags (Bag a) (Bag a)

mapBagM :: Monad m => (a -> m b) -> Bag a -> m (Bag b)
mapBagM _ EmptyBag        = return EmptyBag
mapBagM f (UnitBag x)     = UnitBag <$> f x
mapBagM f (TwoBags b1 b2) = do r1 <- mapBagM f b1
                               r2 <- mapBagM f b2
                               return (TwoBags r1 r2)

bagToList :: Bag a -> [a]
bagToList EmptyBag = []
bagToList (UnitBag x) = [x]
bagToList (TwoBags b1 b2) = bagToList b1 ++ bagToList b2

main :: IO ()
main = do
  let bag = TwoBags (UnitBag "five") (UnitBag "six")
  supply <- newSupply 0
  named <- mapBagM (mkName supply) bag
  let xs = bagToList named
  putStrLn ("count: " ++ show (length xs))
  forM_ xs $ \(nm, u) -> putStrLn ("  " ++ nm ++ " uid=" ++ show u)
  -- repeat 3 times to see determinism
  forM_ [1..3] $ \i -> do
    s2 <- newSupply (i * 1000)
    nb <- mapBagM (mkName s2) bag
    putStrLn ("run " ++ show i ++ ": " ++ show (bagToList nb))
