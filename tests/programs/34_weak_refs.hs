-- Weak references + System.Mem.performGC.  Allocate an object,
-- make a weak ref, drop the strong ref, force GC, verify weak is dead.
import System.Mem
import System.Mem.Weak
import Data.IORef

main :: IO ()
main = do
  -- Scope where strong ref lives
  weak <- do
    r <- newIORef (42 :: Int)
    w <- mkWeakIORef r (putStrLn "finalizer ran")
    v <- readIORef r
    putStrLn $ "before GC: " ++ show v
    return w
  -- strong ref went out of scope; force GC
  performGC
  -- Try to deref
  m <- deRefWeak weak
  case m of
    Just r -> do
      v <- readIORef r
      putStrLn $ "still alive: " ++ show v
    Nothing ->
      putStrLn "weak is dead (expected)"
