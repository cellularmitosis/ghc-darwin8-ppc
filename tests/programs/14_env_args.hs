import System.Environment
import System.Exit

main :: IO ()
main = do
  args <- getArgs
  putStrLn $ "getArgs = " ++ show args
  name <- getProgName
  putStrLn $ "getProgName = " ++ name
  mshell <- lookupEnv "SHELL"
  putStrLn $ "SHELL env = " ++ show mshell
  exitWith ExitSuccess
