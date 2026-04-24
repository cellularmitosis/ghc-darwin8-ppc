-- High-level concurrency via `async` package.
import Control.Concurrent.Async
import Control.Concurrent (threadDelay)

main :: IO ()
main = do
  a <- async (do threadDelay 100000; return (2 + 2))
  b <- async (do threadDelay 50000; return "hello")
  r1 <- wait a
  r2 <- wait b
  putStrLn $ "a: " ++ show r1
  putStrLn $ "b: " ++ show r2
  (x, y) <- concurrently
    (do threadDelay 30000; return (42 :: Int))
    (do threadDelay 60000; return "world")
  putStrLn $ "concurrent: " ++ show (x, y)
