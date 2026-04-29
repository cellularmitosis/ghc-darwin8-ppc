{-# LANGUAGE OverloadedStrings #-}
import OpenSSL
import OpenSSL.Session as SSL
import qualified Network.Socket as N
import qualified Network.Socket.ByteString as NBS
import qualified Data.ByteString.Char8 as BS
import Control.Exception (bracket, try, SomeException)

trace :: String -> IO ()
trace s = putStrLn ("TRACE: " ++ s)

main :: IO ()
main = withOpenSSL $ N.withSocketsDo $ do
    trace "creating SSL context"
    ctx <- SSL.context
    SSL.contextSetVerificationMode ctx SSL.VerifyNone
    SSL.contextSetDefaultCiphers ctx
    addr:_ <- N.getAddrInfo
        (Just N.defaultHints { N.addrSocketType = N.Stream
                             , N.addrFamily = N.AF_INET })
        (Just "example.com") (Just "443")
    sock <- N.openSocket addr
    N.connect sock (N.addrAddress addr)
    trace "wrapping in SSL"
    ssl <- SSL.connection ctx sock
    -- SNI is required by modern TLS servers
    SSL.setTlsextHostName ssl "example.com"
    trace "ssl connect (handshake)"
    SSL.connect ssl
    trace "TLS handshake complete!"
    SSL.write ssl "GET / HTTP/1.0\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    chunk <- SSL.read ssl 512
    putStrLn $ "first 512 bytes:"
    BS.putStr chunk
    putStrLn ""
    SSL.shutdown ssl SSL.Unidirectional
    N.close sock
