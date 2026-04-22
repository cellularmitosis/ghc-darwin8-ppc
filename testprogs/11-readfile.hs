-- File I/O.  Reads its own source via __FILE__-equivalent... actually,
-- just reads /etc/hosts which exists on every Darwin.  Validates
-- System.IO + the RTS file-descriptor machinery + iconv text decode.
main :: IO ()
main = do
  s <- readFile "/etc/hosts"
  if length s > 0
     then putStrLn ("OK 11-readfile (" ++ show (length s) ++ " bytes)")
     else error "FAIL 11-readfile: empty"
