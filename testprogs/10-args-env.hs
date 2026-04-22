-- System.Environment: getArgs, lookupEnv (or getEnvironment for older base).
import System.Environment (getArgs, getEnvironment)

main :: IO ()
main = do
  args <- getArgs
  env  <- getEnvironment
  let path = lookup "PATH" env
  case path of
    Nothing -> error "FAIL 10-args-env: no PATH"
    Just _  -> putStrLn ("OK 10-args-env (argc=" ++ show (length args) ++ ")")
