{-# LANGUAGE OverloadedStrings #-}
-- A localhost TCP echo round-trip using vendored network-3.2.8.0 on Tiger.
import qualified Network.Socket as N
import Control.Exception (bracket)
import Control.Concurrent (forkIO, threadDelay)
import qualified Network.Socket.ByteString as NBS
import qualified Data.ByteString.Char8 as BS

server :: N.Socket -> IO ()
server sock = do
    (cli, _) <- N.accept sock
    msg <- NBS.recv cli 1024
    NBS.sendAll cli (BS.append "echo: " msg)
    N.close cli

main :: IO ()
main = N.withSocketsDo $ do
    addr:_ <- N.getAddrInfo
        (Just N.defaultHints { N.addrFlags = [N.AI_PASSIVE]
                             , N.addrFamily = N.AF_INET
                             , N.addrSocketType = N.Stream })
        Nothing (Just "0")
    bracket
      (do s <- N.openSocket addr
          N.bind s (N.addrAddress addr)
          N.listen s 1
          return s)
      N.close
      $ \s -> do
          port <- N.socketPort s
          putStrLn $ "server listening on port " ++ show port
          _ <- forkIO (server s)
          threadDelay 100000

          caddr:_ <- N.getAddrInfo
              (Just N.defaultHints { N.addrFamily = N.AF_INET
                                   , N.addrSocketType = N.Stream })
              (Just "127.0.0.1") (Just (show port))
          c <- N.openSocket caddr
          N.connect c (N.addrAddress caddr)
          NBS.sendAll c "hello tiger"
          reply <- NBS.recv c 1024
          BS.putStr reply
          putStrLn ""
          N.close c
