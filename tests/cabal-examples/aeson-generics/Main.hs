-- JSON encode/decode via Generics (not Template Haskell — TH doesn't
-- work on Tiger until the GHCi loader is restored).
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as BL
import GHC.Generics

data Person = Person { name :: String, age :: Int } deriving (Generic, Show)
instance ToJSON Person
instance FromJSON Person

main :: IO ()
main = do
  let p = Person "alice" 30
  let j = encode p
  BL.putStrLn j
  case decode j :: Maybe Person of
    Just p' -> putStrLn $ "decoded: " ++ show p'
    Nothing -> putStrLn "decode failed"
  -- Array + object
  let big = object ["items" .= [Person "a" 1, Person "b" 2, Person "c" 3]]
  BL.putStrLn (encode big)
