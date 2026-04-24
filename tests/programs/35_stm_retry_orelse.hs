-- STM retry + orElse: consumer waits until >=3 items available, OR
-- a timeout TVar is set.
import Control.Concurrent
import Control.Concurrent.STM

main :: IO ()
main = do
  items <- newTVarIO ([] :: [Int])
  timeout <- newTVarIO False
  done <- newEmptyMVar

  -- Producer: adds 3 items over time
  _ <- forkIO $ do
    mapM_ (\i -> do
      threadDelay 10000
      atomically $ modifyTVar items (i:)
      ) [1,2,3 :: Int]

  -- Consumer: waits until either (len items >= 3) or timeout fires
  _ <- forkIO $ do
    result <- atomically $ do
      xs <- readTVar items
      if length xs >= 3
        then return ("got items: " ++ show (reverse xs))
        else do
          t <- readTVar timeout
          if t then return "timed out"
               else retry
    putStrLn result
    putMVar done ()

  takeMVar done
