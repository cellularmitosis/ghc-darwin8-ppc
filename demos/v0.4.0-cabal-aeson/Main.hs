-- v0.4.0 — Cabal cross-compile works.  This demo uses `aeson`
-- (a Hackage package, ~20 transitive deps) to round-trip a small
-- record through JSON and back, on Tiger PPC.  It's a smaller
-- aeson-Generics example modeled on the working
-- tests/cabal-examples/aeson-generics fixture.
--
-- Build + ship + run from this dir:
--   ../../tests/cabal-examples/run-one.sh \
--       ../../demos/v0.4.0-cabal-aeson
--
-- Or by hand:
--   source ../../scripts/cross-env.sh
--   cabal build --with-compiler=$STAGE1 --with-hsc2hs=$HOST_HSC2HS
--   scp $(find dist-newstyle -name v040-aeson -type f -perm -u+x) tiger:/tmp/
--   ssh tiger /tmp/v040-aeson
--
-- (See docs/cabal-cross.md for the full recipe.)
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Aeson (encode, decode, ToJSON, FromJSON)
import qualified Data.ByteString.Lazy.Char8 as BL
import GHC.Generics (Generic)

data Person = Person
  { name :: String
  , age  :: Int
  , host :: String
  } deriving (Show, Generic)

instance ToJSON Person
instance FromJSON Person

main :: IO ()
main = do
  let p = Person { name = "G5", age = 21, host = "pmacg5" }
  let bs = encode p
  putStrLn $ "encoded: " ++ BL.unpack bs
  case decode bs :: Maybe Person of
    Just p' -> putStrLn $ "decoded: " ++ show p'
    Nothing -> putStrLn "decode failed"
