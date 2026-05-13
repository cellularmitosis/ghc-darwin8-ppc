{-# LANGUAGE MagicHash #-}
{-# LANGUAGE UnboxedTuples #-}
{-# LANGUAGE BangPatterns #-}
{-# OPTIONS_GHC -ddump-stg-final -ddump-to-file -dppr-debug #-}
-- Verify that anyToAddr# returns the actual closure header address
-- without an intervening "unsafeCoerce v :: Any" wrapping thunk
-- (which probe35 in session 35 turned out to be reading).
--
-- Three test cases:
--   (1) a known-WHNF value (a pre-evaluated Just 42) — we expect the
--       captured info-table to be a constructor info table.
--   (2) a known-thunk value (lazy `Just (factorial 30)`) — we expect
--       a THUNK info table BEFORE seq and a constructor info table AFTER.
--   (3) a polymorphic argument like `refineFromInScope`'s `v :: Var`
--       receives — simulated as `Int -> String` to force GHC's STG
--       through the same path.
--
-- For each test we dump (a) the captured Word-encoded addr, (b) the
-- first 4 heap words at that address.  The -ddump-stg-final pragma at
-- the top makes GHC emit the STG so we can inspect whether the
-- argument is being let-bound to a wrapping thunk before the primop
-- call (the artifact session 35 found).

module Main where

import GHC.Exts (anyToAddr#, Addr#, addr2Int#, Int#)
import GHC.Int  (Int(..))
import GHC.Word (Word(..))
import GHC.Prim (int2Word#)
import GHC.IO   (IO(..))
import Foreign.Ptr     (Ptr, wordPtrToPtr, plusPtr)
import Foreign.Storable (peek)
import Data.Bits       ((.&.), complement)
import qualified Numeric (showHex)
import System.IO       (hPutStrLn, stderr, hFlush)
import System.IO.Unsafe (unsafePerformIO)

hex :: Word -> String
hex w = "0x" ++ Numeric.showHex w ""

-- The probe.  This is the design we want to validate.
addressOf :: a -> IO Word
addressOf x = IO $ \s ->
    case anyToAddr# x s of
      (# s', addr #) -> (# s', W# (int2Word# (addr2Int# addr)) #)

readHeader :: Word -> IO [Word]
readHeader addr =
    let !base = addr .&. complement 3   -- PPC32 tag mask = 3
    in mapM (\i -> peek (wordPtrToPtr (fromIntegral base) `plusPtr` (i * wordSize)
                          :: Ptr Word))
            [0 .. 3]

-- 4 bytes on 32-bit, 8 on 64-bit; this program is verified on both.
wordSize :: Int
wordSize = sizeOfWord (undefined :: Word)
  where sizeOfWord :: Word -> Int
        sizeOfWord _ = case () of
            _ | maxBoundWord >= 0xffffffffffffffff -> 8
              | otherwise -> 4
        maxBoundWord :: Word
        maxBoundWord = maxBound

-- {-# NOINLINE #-} is critical: without it GHC may rewrite the call
-- and inline the body, eliminating the thunk allocation.
{-# NOINLINE probe #-}
probe :: String -> a -> IO ()
probe label x = do
    !addr <- addressOf x
    ws <- readHeader addr
    hPutStrLn stderr $ label ++ ": @" ++ hex addr ++ " ["
                    ++ unwords (map hex ws) ++ "]"
    hFlush stderr

-- ---------------------------------------------------------------------
-- Test fixtures
-- ---------------------------------------------------------------------

-- T1: a known-WHNF value.  ! pattern + literal constructor → WHNF.
{-# NOINLINE knownWhnf #-}
knownWhnf :: Maybe Int
knownWhnf = Just 42

-- T2: a known thunk.  Lazy let-binding + a moderately expensive
-- non-trivial expression.  We expect the info-pointer pre-seq to be
-- a THUNK, and post-seq to be a constructor (Just_con_info or similar).
{-# NOINLINE knownThunk #-}
knownThunk :: Maybe Int
knownThunk = Just $! lengthListN 100   -- $! to ensure inner is WHNF too
                                       -- but the outer is still a CAF
                                       -- thunk on first access.

{-# NOINLINE lengthListN #-}
lengthListN :: Int -> Int
lengthListN n = length (replicate n ())

-- T3: structurally polymorphic argument.  We pass a `Var`-like Id
-- and a typeclass-dictionary-like value.  But we cannot construct a
-- real GHC `Var` here, so we use a stand-in: a strict newtype around
-- a function pointer, mimicking the layout of a constructor.
data SimVar = SimVar !Int
{-# NOINLINE simVar #-}
simVar :: SimVar
simVar = SimVar 7

-- ---------------------------------------------------------------------
-- Main: probe each fixture before+after `seq`
-- ---------------------------------------------------------------------

main :: IO ()
main = do
    -- T1: known WHNF
    probe "T1-knownWhnf-BEFORE  " knownWhnf
    knownWhnf `seq` return ()
    probe "T1-knownWhnf-AFTER   " knownWhnf

    -- T2: known thunk (CAF — first access forces it).
    probe "T2-knownThunk-BEFORE " knownThunk
    knownThunk `seq` return ()
    probe "T2-knownThunk-AFTER  " knownThunk

    -- T3: small strict constructor.
    probe "T3-simVar-BEFORE     " simVar
    simVar `seq` return ()
    probe "T3-simVar-AFTER      " simVar
