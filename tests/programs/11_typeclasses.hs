class Greeting a where
  greet :: a -> String

data Human = Human String
data Dog = Dog String

instance Greeting Human where
  greet (Human n) = "Hello, " ++ n

instance Greeting Dog where
  greet (Dog n) = "Woof woof, says " ++ n

class Container f where
  empty :: f a
  insert' :: a -> f a -> f a
  toList' :: f a -> [a]

newtype Stack a = Stack [a]
newtype Queue a = Queue ([a], [a])

instance Container Stack where
  empty = Stack []
  insert' x (Stack xs) = Stack (x:xs)
  toList' (Stack xs) = xs

main :: IO ()
main = do
  putStrLn (greet (Human "alice"))
  putStrLn (greet (Dog "rex"))
  let s = foldr insert' (empty :: Stack Int) [1,2,3,4,5]
  putStrLn $ "stack: " ++ show (toList' s)
