-- Parser combinator demo via `megaparsec`.  Parses "name=num" pairs
-- separated by ", ".
{-# LANGUAGE OverloadedStrings #-}
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Void
import Data.Text (Text)

type Parser = Parsec Void Text

pairP :: Parser (String, Int)
pairP = (,) <$> (many alphaNumChar <* char '=') <*> L.decimal

pairsP :: Parser [(String, Int)]
pairsP = pairP `sepBy` string ", "

main :: IO ()
main = do
  let input = "alice=30, bob=25, charlie=42" :: Text
  case parse (pairsP <* eof) "input" input of
    Right pairs -> do
      putStrLn "parsed:"
      mapM_ print pairs
    Left err -> putStr (errorBundlePretty err)
