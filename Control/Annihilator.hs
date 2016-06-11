

-- | A pair of classes Annihilator and Annihilating which respectively define
-- an annihilating element 'ann' and a binary function '>&>' that follows the
-- mathematical properties of annihilating (absorbing element) and associativity.
--
-- If you consider 'Control.Applicative.Alternative' to be OR, this is the AND
-- analogous to that, e.g. in Alternative
--
-- > Nothing <|> Nothing == Nothing
-- > Nothing <|> Just 1 == Just 1
-- > Just 1 <|> Nothing == Just 1
-- > Just 1 <|> Just 2 == Just 1
--
-- whereas with Annihilators
--
-- > Nothing <&< Nothing == Nothing
-- > Nothing <&< Just 1 == Nothing
-- > Just 1 <&< Nothing == Nothing
-- > Just 1 <&< Just 2 == Just 1
--
-- This is useful when reasoning about datatypes with failures such as
-- 'Maybe' or '[a]'.
--
module Control.Annihilator
    ( Annihilator(..)
    , Annihilating(..)
    , (<&<)
    , aconcat
    , amappend
    , amconcat
    , avoid
    )
    where


import Data.Monoid (Sum(..), Product(..), Any(..), All(..))


infixr 7 >&>
infixl 7 <&<


-- | Annihilators are semigroups with an absorbing element, i.e. the
-- following laws should hold:
--
-- __Absorbing element__
--
-- prop> ann >&> b == ann
-- prop> a >&> ann == ann
--
-- __Associativity__
--
-- prop> (a >&> b) >&> c == a >&> (b >&> c)
--
class Annihilating a where
    -- | Annihilating operator, returns the rightmost argument on success, i.e.
    --   if no annihilators 'ann' are present.
    (>&>) :: a -> a -> a

class Annihilating a => Annihilator a where
    -- | Annihilating element of '>&>'.
    ann :: a


instance Annihilator () where
    ann = ()
    {-# INLINE ann #-}

instance Annihilating () where
    _ >&> _ = ()
    {-# INLINE (>&>) #-}

instance Annihilator (Maybe a) where
    ann = Nothing
    {-# INLINE ann #-}

instance Annihilating (Maybe a) where
    Nothing >&> _ = Nothing
    _ >&> Nothing = Nothing
    _ >&> a = a
    {-# INLINE (>&>) #-}

instance Annihilating (Either a b) where
    (Left a) >&> _ = Left a
    _ >&> (Left b) = Left b
    _ >&> b = b
    {-# INLINE (>&>) #-}

instance Annihilator ([] a) where
    ann = []
    {-# INLINE ann #-}

instance Annihilating ([] a) where
    [] >&> _ = []
    _ >&> [] = []
    _ >&> a = a
    {-# INLINE (>&>) #-}

instance (Annihilator a, Annihilator b) => Annihilator (a, b) where
    ann = (ann, ann)
    {-# INLINE ann #-}

instance (Annihilating a, Annihilating b) => Annihilating (a, b) where
    (a1, b1) >&> (a2, b2) = (a1 >&> a2, b1 >&> b2)
    {-# INLINE (>&>) #-}

instance (Annihilator a, Annihilator b, Annihilator c) => Annihilator (a, b, c) where
    ann = (ann, ann, ann)
    {-# INLINE ann #-}

instance (Annihilating a, Annihilating b, Annihilating c) => Annihilating (a, b, c) where
    (a1, b1, c1) >&> (a2, b2, c2) = (a1 >&> a2, b1 >&> b2, c1 >&> c2)
    {-# INLINE (>&>) #-}

instance Annihilator All where
    ann = All False
instance Annihilating All where
    All x >&> All y = All (x && y)

instance Annihilator Product where
    ann = Product 0
instance Annihilating Product where
    x >&> y = Product (getProduct x * getProduct y)


-- | Flipped version of '>&>'. Returns the leftmost argument on success.
(<&<) :: Annihilating a => a -> a -> a
(<&<) = flip (>&>)
{-# INLINE (<&<) #-}

-- | Annihilating concatenation. Returns the last element on success.
aconcat :: (Annihilator a, Foldable t) => t a -> a
aconcat as
    | null as   = ann
    | otherwise = foldr1 (>&>) as
{-# INLINE aconcat #-}

-- | Monadic append with the annihilating operator guarding each argument.
--   Returns the mappended result on success.
amappend :: (Annihilating a, Monoid a) => a -> a -> a
amappend a b = (a <&< b) `mappend` (a >&> b)
{-# INLINE amappend #-}

-- | Monadic concatenation with the annihilating operator guarding each argument.
amconcat :: (Annihilator a, Monoid a, Foldable t) => t a -> a
amconcat as
    | null as   = ann
    | otherwise = foldr1 amappend as
{-# INLINE amconcat  #-}

isAnn :: (Annihilator a, Eq a) => a -> Bool
isAnn = (ann ==)

-- | Discard the argument and return 'ann'.
avoid :: Annihilator a => b -> a
avoid = const ann
{-# INLINE avoid #-}

