-- TCP echo server + client in one binary (forkIO-separated, both
-- talking to 127.0.0.1).  Tests sockets with `network < 3.0`.
import Network.Socket
import qualified Network.Socket.ByteString as NSB
import qualified Data.ByteString.Char8 as BS
import Control.Concurrent

server :: Socket -> MVar Int -> IO ()
server sock portVar = do
  addr <- head <$> getAddrInfo
    (Just defaultHints { addrFamily = AF_INET })
    (Just "127.0.0.1") (Just "0")
  bind sock (addrAddress addr)
  listen sock 1
  SockAddrInet p _ <- getSocketName sock
  putMVar portVar (fromIntegral p)
  (conn, _) <- accept sock
  msg <- NSB.recv conn 1024
  NSB.sendAll conn (BS.pack "re: " `BS.append` msg)
  close conn

main :: IO ()
main = do
  srv <- socket AF_INET Stream defaultProtocol
  portVar <- newEmptyMVar
  _ <- forkIO (server srv portVar)
  port <- takeMVar portVar
  putStrLn $ "server listening on " ++ show port

  client <- socket AF_INET Stream defaultProtocol
  addr <- head <$> getAddrInfo
    (Just defaultHints { addrFamily = AF_INET })
    (Just "127.0.0.1") (Just (show port))
  connect client (addrAddress addr)
  NSB.sendAll client (BS.pack "hello tiger")
  reply <- NSB.recv client 1024
  putStrLn $ "got: " ++ BS.unpack reply
  close client
  close srv
