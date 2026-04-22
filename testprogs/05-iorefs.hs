-- IORef mutation — exercises RTS heap mutation, write barriers,
-- the strict/lazy distinction at the IORef payload level.
import Data.IORef

main :: IO ()
main = do
  r <- newIORef (0 :: Int)
  mapM_ (\x -> modifyIORef r (+ x)) [1..100]
  v <- readIORef r
  if v == 5050
     then putStrLn "OK 05-iorefs"
     else error ("FAIL 05-iorefs: got " ++ show v)
