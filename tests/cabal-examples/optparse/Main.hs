-- CLI arg parsing via `optparse-applicative`.  Exercises help text,
-- arg validation, default values.
import Options.Applicative

data Cfg = Cfg { cfgName :: String, cfgCount :: Int } deriving Show

cfgP :: Parser Cfg
cfgP = Cfg
  <$> strOption  (long "name" <> short 'n' <> metavar "NAME" <> help "Your name")
  <*> option auto (long "count" <> short 'c' <> metavar "N" <> value 1 <> help "Repetitions")

main :: IO ()
main = do
  cfg <- execParser (info (cfgP <**> helper)
           (fullDesc <> progDesc "Greet someone"))
  mapM_ (\_ -> putStrLn $ "Hello, " ++ cfgName cfg ++ "!") [1..cfgCount cfg]
