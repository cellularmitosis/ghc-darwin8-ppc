-- STM: bank-account transfers.  Two accounts, 100 random transfers
-- each of 10, some of which should retry.  Total balance invariant
-- must hold.
import Control.Concurrent
import Control.Concurrent.STM
import Control.Monad (forM_, replicateM_)

transfer :: TVar Int -> TVar Int -> Int -> STM ()
transfer from to amount = do
  fromBal <- readTVar from
  if fromBal < amount
    then retry
    else do
      writeTVar from (fromBal - amount)
      toBal <- readTVar to
      writeTVar to (toBal + amount)

main :: IO ()
main = do
  a <- newTVarIO 500
  b <- newTVarIO 500
  done <- newEmptyMVar
  -- 2 threads transferring back and forth
  _ <- forkIO $ do
    replicateM_ 50 (atomically (transfer a b 5))
    putMVar done ()
  _ <- forkIO $ do
    replicateM_ 50 (atomically (transfer b a 5))
    putMVar done ()
  takeMVar done
  takeMVar done
  (fa, fb) <- atomically $ do
    fa <- readTVar a
    fb <- readTVar b
    return (fa, fb)
  putStrLn $ "account a: " ++ show fa
  putStrLn $ "account b: " ++ show fb
  putStrLn $ "total: " ++ show (fa + fb)
  putStrLn $ "invariant (1000): " ++ show (fa + fb == 1000)
