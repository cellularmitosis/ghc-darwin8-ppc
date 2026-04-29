{-# LANGUAGE ScopedTypeVariables, RecordWildCards #-}
import qualified Data.ByteString.Lazy as LB
import Data.Binary.Get
import Data.Binary (get, Get)
import GHCi.ResolvedBCO
import Data.Array.Unboxed
import Data.Word
import GHC.Data.SizedSeq

main :: IO ()
main = do
  bs <- LB.readFile "bco-blob.bin"
  putStrLn $ "blob size: " ++ show (LB.length bs)
  let rbcos = runGet (get :: Get [ResolvedBCO]) bs
  putStrLn $ "decoded " ++ show (length rbcos) ++ " ResolvedBCOs"
  mapM_ describe rbcos
  where
    describe ResolvedBCO{..} = do
      putStrLn $ "  isLE=" ++ show resolvedBCOIsLE
      putStrLn $ "  arity=" ++ show resolvedBCOArity
      putStrLn $ "  instrs.bounds=" ++ show (bounds resolvedBCOInstrs)
      putStrLn $ "  instrs=" ++ show (elems resolvedBCOInstrs)
      putStrLn $ "  bitmap.bounds=" ++ show (bounds resolvedBCOBitmap)
      putStrLn $ "  bitmap=" ++ show (elems resolvedBCOBitmap)
      putStrLn $ "  lits.bounds=" ++ show (bounds resolvedBCOLits)
      putStrLn $ "  lits=" ++ show (elems resolvedBCOLits)
      putStrLn $ "  ptrs size=" ++ show (sizeSS resolvedBCOPtrs)
      putStrLn $ "  ptrs=" ++ show (ssElts resolvedBCOPtrs)
