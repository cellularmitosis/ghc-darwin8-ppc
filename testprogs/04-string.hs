-- String operations exercise the RTS allocator (each Char is heap-allocated
-- in old-style String, every cons cell is a separate object).
main :: IO ()
main = do
  let s   = concat (replicate 100 "abc")
      r   = reverse s
      len = length s
  if len == 300
       && take 5 s == "abcab"
       && take 5 r == "cbacb"
     then putStrLn "OK 04-string"
     else error ("FAIL 04-string: " ++ show (len, take 5 s, take 5 r))
