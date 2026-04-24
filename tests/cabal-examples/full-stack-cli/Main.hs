-- End-to-end demo combining aeson + vector + optparse-applicative.
-- Reads a JSON array of {name, age} objects from a file, sorts by
-- age, prints as a table.
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Data.Aeson
import qualified Data.ByteString.Lazy as BL
import qualified Data.Vector as V
import Data.List (sortOn)
import GHC.Generics
import Options.Applicative

data Person = Person { name :: String, age :: Int } deriving (Generic, Show)
instance ToJSON Person
instance FromJSON Person

data Cfg = Cfg { cfgInput :: FilePath, cfgDescending :: Bool }

cfgP :: Parser Cfg
cfgP = Cfg
  <$> strOption (long "input" <> short 'i' <> metavar "FILE" <> help "JSON file")
  <*> switch (long "desc" <> help "Sort descending")

main :: IO ()
main = do
  cfg <- execParser (info (cfgP <**> helper) (progDesc "Sort JSON people by age"))
  bs <- BL.readFile (cfgInput cfg)
  case eitherDecode bs of
    Left err -> putStrLn $ "parse error: " ++ err
    Right (people :: V.Vector Person) -> do
      let sorted = V.fromList . (if cfgDescending cfg then reverse else id)
                 . sortOn age . V.toList $ people
      putStrLn "NAME       AGE"
      putStrLn "------------------"
      V.mapM_ (\p -> putStrLn $ pad 10 (name p) ++ " " ++ show (age p)) sorted
  where
    pad n s = s ++ replicate (max 0 (n - length s)) ' '
