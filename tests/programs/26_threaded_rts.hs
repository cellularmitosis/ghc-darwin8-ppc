-- Exercise the threaded RTS: spawn 4 threads, each increments a
-- shared counter 250,000 times atomically.  Total should be 1,000,000.
-- Compile with: -threaded
import Control.Concurrent
import Control.Concurrent.MVar
import Data.IORef
import Control.Monad (replicateM_, forM_)

main :: IO ()
main = do
  caps <- getNumCapabilities
  counter <- newIORef (0 :: Int)
  done <- newEmptyMVar
  let n_threads = 4 :: Int
      per_thread = 250000 :: Int
  forM_ [1..n_threads] $ \_ -> forkIO $ do
    replicateM_ per_thread (atomicModifyIORef' counter (\x -> (x+1, ())))
    putMVar done ()
  replicateM_ n_threads (takeMVar done)
  final <- readIORef counter
  putStrLn $ "capabilities: " ++ show caps
  putStrLn $ "threads: " ++ show n_threads
  putStrLn $ "per_thread increments: " ++ show per_thread
  putStrLn $ "final counter: " ++ show final
  putStrLn $ "expected: " ++ show (n_threads * per_thread)
  putStrLn $ "correct: " ++ show (final == n_threads * per_thread)
