{-# LANGUAGE MagicHash #-}
{-# LANGUAGE UnboxedTuples #-}
{-# LANGUAGE BangPatterns #-}
module Main where

import GHC.Exts
import GHC.IO
import Foreign.Marshal.Alloc (mallocBytes, free)
import Foreign.Ptr
import Foreign.Storable
import GHC.IO.Unsafe (unsafeDupableInterleaveIO)
import Data.Bits

-- Reproduce mkSplitUniqSupply behaviour without depending on ghc package.

data USup = MkSup !Int USup USup

fetchAdd :: Ptr Word -> Word -> IO Word
fetchAdd (Ptr addr#) (W# val#) = IO $ \s0 ->
  case fetchAddWordAddr# addr# val# s0 of
    (# s1, old# #) -> (# s1, W# old# #)

mkSplit :: Ptr Word -> Char -> IO USup
mkSplit ctr c = unsafeDupableInterleaveIO (IO (mk_supply ctr c))
  where
    !maskW = fromIntegral (fromEnum c) `unsafeShiftL` 24
    mk_supply :: Ptr Word -> Char -> State# RealWorld -> (# State# RealWorld, USup #)
    mk_supply ctr' c' s0 =
      case noDuplicate# s0 of { s1 ->
      case unIO (fetchAdd ctr' 1) s1 of { (# s2, u #) ->
      case unIO (unsafeDupableInterleaveIO (IO (mk_supply ctr' c'))) s2 of { (# s3, x #) ->
      case unIO (unsafeDupableInterleaveIO (IO (mk_supply ctr' c'))) s3 of { (# s4, y #) ->
      (# s4, MkSup (maskW .|. fromIntegral u) x y #)
      }}}}

uniqOf :: USup -> Int
uniqOf (MkSup n _ _) = n

splitS :: USup -> (USup, USup)
splitS (MkSup _ s1 s2) = (s1, s2)

uniqsFromSupply :: USup -> [Int]
uniqsFromSupply (MkSup n _ s2) = n : uniqsFromSupply s2

main :: IO ()
main = do
  ctr <- mallocBytes 8 :: IO (Ptr Word)
  poke ctr (0 :: Word)
  sup <- mkSplit ctr 's'
  -- take 20 uniques
  let xs = take 20 (uniqsFromSupply sup)
  putStrLn ("first 20 uniques: " ++ show xs)
  v <- peek ctr
  putStrLn ("counter end: " ++ show v)
  free ctr
