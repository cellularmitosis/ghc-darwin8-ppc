import Data.IORef
import Control.Concurrent.MVar

main :: IO ()
main = do
  r <- newIORef (0 :: Int)
  writeIORef r 42
  v <- readIORef r
  putStrLn $ "IORef value = " ++ show v
  modifyIORef r (+10)
  v' <- readIORef r
  putStrLn $ "after +10 = " ++ show v'

  -- MVar
  m <- newMVar "hello"
  s <- readMVar m
  putStrLn $ "MVar: " ++ s
  modifyMVar_ m (return . (++ " world"))
  s' <- readMVar m
  putStrLn $ "after modify: " ++ s'
