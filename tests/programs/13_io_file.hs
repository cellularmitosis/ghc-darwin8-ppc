import System.IO

main :: IO ()
main = do
  let path = "/tmp/ghc-ppc-test-io.txt"
  let content = "hello from ppc\nline 2\nline 3\n"
  writeFile path content
  putStrLn $ "Wrote " ++ show (length content) ++ " bytes to " ++ path
  back <- readFile path
  putStrLn $ "Read back " ++ show (length back) ++ " bytes"
  putStrLn "=== content ==="
  putStr back
  putStrLn "=== end ==="
  -- Line-by-line read
  h <- openFile path ReadMode
  l1 <- hGetLine h
  putStrLn $ "first line: " ++ l1
  hClose h
