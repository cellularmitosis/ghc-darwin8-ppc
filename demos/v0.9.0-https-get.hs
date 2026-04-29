{-# LANGUAGE OverloadedStrings #-}
-- v0.9.0 demo: HTTPS GET from a Haskell program running on Tiger.
--
-- Builds against vendored HsOpenSSL (with a small runInBoundThread fallback
-- patch) + vendored network-3.x + the openssl-1.1.1t library that
-- tiger.sh ships to /opt/openssl-1.1.1t/.
--
-- Builds:
--   $ tests/cabal-examples/run-one.sh https-get
--
-- Output:
--   TRACE: TLS handshake complete!
--   first 512 bytes:
--   HTTP/1.1 200 OK
--   Date: ...
--   Content-Type: text/html
--   Server: cloudflare
--   ...
--   <title>Example Domain</title>
--
-- This is real-world TLS 1.x to a real internet server (example.com via
-- Cloudflare), running natively on a PowerMac G5 / Tiger 10.4.11.

module Main where

import OpenSSL
import OpenSSL.Session as SSL
import qualified Network.Socket as N
import qualified Data.ByteString.Char8 as BS

main :: IO ()
main = withOpenSSL $ N.withSocketsDo $ do
    putStrLn "creating SSL context"
    ctx <- SSL.context
    SSL.contextSetVerificationMode ctx SSL.VerifyNone
    SSL.contextSetDefaultCiphers ctx
    addr:_ <- N.getAddrInfo
        (Just N.defaultHints { N.addrSocketType = N.Stream
                             , N.addrFamily = N.AF_INET })
        (Just "example.com") (Just "443")
    sock <- N.openSocket addr
    N.connect sock (N.addrAddress addr)
    putStrLn "wrapping in SSL"
    ssl <- SSL.connection ctx sock
    SSL.setTlsextHostName ssl "example.com"
    putStrLn "TLS handshake..."
    SSL.connect ssl
    putStrLn "Handshake complete!"
    SSL.write ssl "GET / HTTP/1.0\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    chunk <- SSL.read ssl 512
    BS.putStr chunk
    putStrLn ""
    SSL.shutdown ssl SSL.Unidirectional
    N.close sock
