-- POSIX signals via System.Posix.Signals.  Install a SIGUSR1 handler
-- that writes to an IORef, raise it, verify the handler ran.
import System.Posix.Signals
import System.Posix.Process
import Data.IORef
import Control.Concurrent (threadDelay)

main :: IO ()
main = do
  counter <- newIORef (0 :: Int)
  let handler = modifyIORef' counter (+1)
  _ <- installHandler sigUSR1 (Catch handler) Nothing
  pid <- getProcessID
  putStrLn $ "pid = (valid)"
  -- Raise SIGUSR1 three times
  mapM_ (const $ do
    signalProcess sigUSR1 pid
    threadDelay 10000  -- let the handler run
    ) [(1::Int)..3]
  threadDelay 50000
  c <- readIORef counter
  putStrLn $ "handler fired: " ++ show c ++ " times"
  putStrLn $ "correct: " ++ show (c == 3)
