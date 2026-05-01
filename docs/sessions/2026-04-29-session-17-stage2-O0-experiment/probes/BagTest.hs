{-# LANGUAGE BangPatterns #-}
module Main where

-- Replicate GHC.Data.Bag's structure
data Bag a
  = EmptyBag
  | UnitBag a
  | TwoBags (Bag a) (Bag a)
  | ListBag [a]

unitBag :: a -> Bag a
unitBag = UnitBag

unionBags :: Bag a -> Bag a -> Bag a
unionBags EmptyBag b = b
unionBags b EmptyBag = b
unionBags b1 b2 = TwoBags b1 b2

snocBag :: Bag a -> a -> Bag a
snocBag b x = b `unionBags` (unitBag x)

mapBagM :: Monad m => (a -> m b) -> Bag a -> m (Bag b)
mapBagM _ EmptyBag        = return EmptyBag
mapBagM f (UnitBag x)     = do r <- f x
                               return (UnitBag r)
mapBagM f (TwoBags b1 b2) = do r1 <- mapBagM f b1
                               r2 <- mapBagM f b2
                               return (TwoBags r1 r2)
mapBagM f (ListBag    xs) = do rs <- mapM f xs
                               return (ListBag rs)

bagToList :: Bag a -> [a]
bagToList EmptyBag        = []
bagToList (UnitBag x)     = [x]
bagToList (TwoBags b1 b2) = bagToList b1 ++ bagToList b2
bagToList (ListBag xs)    = xs

bagSize :: Bag a -> Int
bagSize EmptyBag        = 0
bagSize (UnitBag _)     = 1
bagSize (TwoBags b1 b2) = bagSize b1 + bagSize b2
bagSize (ListBag xs)    = length xs

-- Build "two bindings"-shaped bag via the same path the parser uses:
-- start from emptyRdrGroup (EmptyBag), then snocBag for each binding.
buildBag :: [Int] -> Bag Int
buildBag = foldl snocBag EmptyBag

renamePass :: Int -> IO Int
renamePass x = do
  putStrLn ("renaming: " ++ show x)
  return (x * 10)

main :: IO ()
main = do
  let bag = buildBag [1, 2]
  putStrLn ("initial bag size: " ++ show (bagSize bag))
  putStrLn ("initial bag list: " ++ show (bagToList bag))
  rn <- mapBagM renamePass bag
  putStrLn ("after rn size: " ++ show (bagSize rn))
  putStrLn ("after rn list: " ++ show (bagToList rn))
  -- Bigger
  let bag10 = buildBag [1..10]
  putStrLn ("bag10 size: " ++ show (bagSize bag10))
  putStrLn ("bag10 list: " ++ show (bagToList bag10))
