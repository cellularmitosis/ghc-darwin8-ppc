-- Producer-consumer with 2 producers + 2 consumers over an MVar
-- "channel".  Each producer produces 100 items; consumers print them
-- sorted at the end.  Tests MVar correctness under contention on
-- non-threaded RTS.
import Control.Concurrent
import Control.Concurrent.MVar
import Data.List (sort)
import Data.IORef
import Control.Monad (forM_, replicateM_)

main :: IO ()
main = do
  chan <- newEmptyMVar
  collected <- newMVar ([] :: [Int])
  doneP <- newEmptyMVar
  doneC <- newEmptyMVar
  let nProducers = 2
      perProducer = 100
  forM_ [1..nProducers] $ \p -> forkIO $ do
    forM_ [1..perProducer] $ \i -> do
      putMVar chan (p * 1000 + i)
    putMVar doneP ()
  -- Consumers read until signaled.  Simple approach: read exactly
  -- nProducers*perProducer items total.
  let totalItems = nProducers * perProducer
  let nConsumers = 2
      perConsumer = totalItems `div` nConsumers
  forM_ [1..nConsumers] $ \_ -> forkIO $ do
    replicateM_ perConsumer $ do
      v <- takeMVar chan
      modifyMVar_ collected (return . (v:))
    putMVar doneC ()
  replicateM_ nProducers (takeMVar doneP)
  replicateM_ nConsumers (takeMVar doneC)
  xs <- readMVar collected
  putStrLn $ "items produced: " ++ show (nProducers * perProducer)
  putStrLn $ "items collected: " ++ show (length xs)
  putStrLn $ "sum: " ++ show (sum xs)
  let expected = sum [p * 1000 + i | p <- [1..nProducers], i <- [1..perProducer]]
  putStrLn $ "expected sum: " ++ show expected
  putStrLn $ "match: " ++ show (sum xs == expected)
