import Data.Array

main :: IO ()
main = do
  let a = listArray (0, 9) [x*x | x <- [0..9]] :: Array Int Int
  print (elems a)
  print (a ! 5)
  print (bounds a)
  -- 2D array
  let m = listArray ((0,0),(2,2)) [1..9] :: Array (Int,Int) Int
  mapM_ (\i -> print [m ! (i,j) | j <- [0..2]]) [0..2]
  -- accumArray
  let hist = accumArray (+) 0 (0, 4) [(c `mod` 5, 1) | c <- [1..20]] :: Array Int Int
  print (elems hist)
