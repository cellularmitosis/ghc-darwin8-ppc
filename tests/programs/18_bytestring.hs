import qualified Data.ByteString.Char8 as BS
import qualified Data.ByteString.Lazy.Char8 as BL

main :: IO ()
main = do
  let s = BS.pack "hello from bytestring"
  BS.putStrLn s
  putStrLn $ "length = " ++ show (BS.length s)
  BS.putStrLn (BS.reverse s)
  BS.putStrLn (BS.map (\c -> if c == 'o' then '0' else c) s)
  -- Lazy
  let l = BL.pack "lazy bytestring works too"
  BL.putStrLn l
  putStrLn $ "lazy length = " ++ show (BL.length l)
