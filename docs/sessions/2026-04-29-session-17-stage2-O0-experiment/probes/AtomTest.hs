{-# LANGUAGE MagicHash #-}
{-# LANGUAGE UnboxedTuples #-}
module Main where

import GHC.Exts
import GHC.IO
import GHC.Word
import Foreign.Marshal.Alloc (mallocBytes, free)
import Foreign.Ptr
import Foreign.Storable

-- Mimic genSym: atomic fetch-and-add via fetchAddWordAddr#
fetchAdd :: Ptr Word -> Word -> IO Word
fetchAdd (Ptr addr#) (W# val#) = IO $ \s0 ->
  case fetchAddWordAddr# addr# val# s0 of
    (# s1, old# #) -> (# s1, W# old# #)

main :: IO ()
main = do
  ptr <- mallocBytes 8 :: IO (Ptr Word)
  poke ptr (0 :: Word)
  -- Take 10 uniques sequentially
  uniques <- mapM (\_ -> fetchAdd ptr 1) [1..10 :: Int]
  putStrLn ("uniques: " ++ show uniques)
  v <- peek ptr
  putStrLn ("counter end: " ++ show v)
  free ptr
