import Control.Concurrent
import Control.Concurrent.MVar

main :: IO ()
main = do
  done <- newEmptyMVar
  result <- newMVar (0 :: Int)
  _ <- forkIO $ do
    modifyMVar_ result (return . (+100))
    putMVar done ()
  _ <- forkIO $ do
    modifyMVar_ result (return . (+1000))
    putMVar done ()
  takeMVar done
  takeMVar done
  final <- readMVar result
  putStrLn $ "Final result: " ++ show final
