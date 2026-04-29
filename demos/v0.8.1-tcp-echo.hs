{-# LANGUAGE OverloadedStrings #-}
-- v0.8.1 demo: vendored network-3.2.8.0 actually moves bytes through TCP
-- on a real Tiger box.
--
-- Spins up a localhost echo server on an ephemeral port; opens a client
-- to it; sends "hello tiger" and prints the server's "echo: hello tiger"
-- reply.  Closes both ends cleanly.
--
-- The fact that this works out of the box (with cabal vendor) means:
--   - getAddrInfo, socket, bind, listen, accept work
--   - connect from a forked IO action works
--   - Network.Socket.ByteString.{send,recv}All work
--   - the run-time is happy with multi-threaded socket I/O
--
-- Build & run:
--   $ tests/cabal-examples/run-one.sh network-echo-three
--   server listening on port 54251
--   echo: hello tiger

module Main where

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
