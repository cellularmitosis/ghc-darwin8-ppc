-- try/catch/throwIO — exercises the RTS exception machinery,
-- catch frames on the stack, the unwinder (such as it is in GHC).
import Control.Exception (try, throwIO, ErrorCall(..), SomeException)

main :: IO ()
main = do
  r <- try (throwIO (ErrorCall "boom")) :: IO (Either SomeException ())
  case r of
    Left e  -> if "boom" `elem` words (show e)
                  then putStrLn "OK 08-exceptions"
                  else error ("FAIL 08-exceptions: wrong msg " ++ show e)
    Right _ -> error "FAIL 08-exceptions: throwIO didn't throw"
