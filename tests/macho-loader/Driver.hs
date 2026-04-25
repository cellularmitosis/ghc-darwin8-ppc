{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE InterruptibleFFI #-}
module Main where

import Foreign
import Foreign.C
import System.Environment
import System.IO

foreign import ccall "initLinker"    c_initLinker    :: IO ()
foreign import ccall "loadObj"       c_loadObj       :: CString -> IO CInt
foreign import ccall "resolveObjs"   c_resolveObjs   :: IO CInt
foreign import ccall "lookupSymbol"  c_lookupSymbol  :: CString -> IO (Ptr ())

foreign import ccall "dynamic"  mkAnswer :: FunPtr (IO CInt) -> IO CInt
foreign import ccall "dynamic"  mkGreet  :: FunPtr (IO ())   -> IO ()

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  hSetBuffering stderr NoBuffering
  args <- getArgs
  case args of
    [objPath] -> go objPath
    _ -> error "usage: driver <path-to-greeter.o>"
  where
    go objPath = do
      c_initLinker
      putStrLn "initLinker: ok"
      rc1 <- withCString objPath c_loadObj
      putStrLn $ "loadObj " ++ show objPath ++ " => " ++ show rc1
      rc2 <- c_resolveObjs
      putStrLn $ "resolveObjs => " ++ show rc2
      withCString "_answer" $ \p -> do
        addr <- c_lookupSymbol p
        putStrLn $ "lookupSymbol(answer) => " ++ show addr
        if addr == nullPtr
          then error "answer not found"
          else do
            n <- mkAnswer (castPtrToFunPtr addr)
            putStrLn $ "answer() returned " ++ show n
      withCString "_greet" $ \p -> do
        addr <- c_lookupSymbol p
        putStrLn $ "lookupSymbol(greet) => " ++ show addr
        if addr == nullPtr
          then error "greet not found"
          else mkGreet (castPtrToFunPtr addr)
      putStrLn "test ok"
