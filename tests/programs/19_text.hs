import qualified Data.Text as T
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
  let t = T.pack "hello from Data.Text"
  TIO.putStrLn t
  putStrLn $ "length = " ++ show (T.length t)
  TIO.putStrLn (T.toUpper t)
  TIO.putStrLn (T.replace (T.pack "hello") (T.pack "HELLO") t)
  let ws = T.words t
  mapM_ TIO.putStrLn ws
