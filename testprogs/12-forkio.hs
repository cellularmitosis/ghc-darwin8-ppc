-- Forked threads + MVar synchronization.  Single-OS-thread RTS by
-- default (no -threaded), so this validates the green-thread scheduler
-- and the RTS preemption mechanism.
import Control.Concurrent     (forkIO)
import Control.Concurrent.MVar

main :: IO ()
main = do
  done <- newEmptyMVar
  count <- newMVar (0 :: Int)
  let n = 50
  mapM_ (\_ -> forkIO $ do
                 modifyMVar_ count (\v -> return (v + 1))
                 putMVar done ())
        [1..n]
  -- wait for all
  mapM_ (\_ -> takeMVar done) [1..n]
  v <- readMVar count
  if v == n
     then putStrLn "OK 12-forkio"
     else error ("FAIL 12-forkio: " ++ show v)
