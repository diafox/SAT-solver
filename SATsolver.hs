{-
Riešiteľ SAT pomocou DPLL algoritmu
Diana Líšková, 2. ročník Bc.
letný semester 2021/22
Neprocedurálne programovanie NPRG005
-}


import Data.Set (Set)
import qualified Data.Set as Set
-- tento package som použila pre šikovnejšie reprezentovanie množín Char-ov

import Control.Applicative ((<|>))
-- modul, z ktorého používam <|> pre výber prvého Just na ktoré natrafíme

data Formula = Var Char                -- reprezentácia premenných
             | And Formula Formula     -- konjunkcie
             | Or Formula Formula      -- disjunkcie
             | Not Formula             -- negácie
             | Const Bool              -- konštantných hodnôt True/False
             deriving (Show, Eq)   

-- premenné môžu mať pravdivostné ohodnotenie True alebo False, avšak tieto výrazy v kóde 
-- použiť nemôžem, preto ich reprezentujem pomocou slov Positive alebo Negative
data BoolValue = Positive           -- True 
               | Negative           -- False
               | Combined 
               deriving (Show, Eq)


-- -- -- -- -- -- konvertovanie do CNF formy -- -- -- -- -- --
-- DPLL algoritmus príjma ako vstupy iba formule v CNF forme 
-- a teda vstupné formule musíme upraviť tak, aby boli CNF

-- aplikovanie De Morganovho pravidla pre odstraňovanie negácii 
removeNeg :: Formula -> Formula
removeNeg expr = 
    case expr of 
        Not (Not x) -> removeNeg x
        Not (And x y) -> Or (removeNeg $ Not x) (removeNeg $ Not y)
        Not (Or x y) -> And (removeNeg $ Not x) (removeNeg $ Not y)
        Not (Const c) -> Const (not c)
        Not x -> Not (removeNeg x)
        And x y -> And (removeNeg x) (removeNeg y)
        Or x y -> Or (removeNeg x) (removeNeg y)
        x -> x

-- 'roznásobenie' zátvoriek a teda distribúcia výrazov v CNF forme
fixDistrib :: Formula -> Formula
fixDistrib expr = 
    case expr of 
        Or x (And y z) -> And (Or (fixDistrib x) (fixDistrib y)) (Or (fixDistrib x) (fixDistrib z))
        Or (And y z) x -> And (Or (fixDistrib x) (fixDistrib y)) (Or (fixDistrib x) (fixDistrib z))
        Or x y -> Or (fixDistrib x) (fixDistrib y)
        And x y -> And (fixDistrib x) (fixDistrib y)
        Not x -> Not (fixDistrib x)
        x -> x 

-- prevod formule do cnf, kontrolujem či je vstupný výraz vo finálnej podobe 
cnf :: Formula -> Formula 
cnf expr 
    | (fixDistrib (removeNeg expr)) == expr = expr
    | otherwise = cnf (fixDistrib (removeNeg expr))


-- -- -- -- -- -- prehľadávanie -- -- -- -- -- --

-- nájdeme prvú nezabranú premennú, tj. premennú bez boolean hodnoty
findVar :: Formula -> Maybe Char
findVar expr = 
    case expr of (Const _) -> Nothing 
                 (Var v)   -> Just v
                 (Not e)   -> findVar e
                 (Or x y)  -> findVar x <|> findVar y
                 (And x y) -> findVar x <|> findVar y 

-- nahradenie nájdenej premennej za hádanú true/false hodnotu 
replaceVar :: Char -> Bool -> Formula -> Formula
replaceVar variable value expr = 
    case expr of 
        (Var v) | v == variable -> Const value
                | otherwise     -> Var v
        (Const c) -> Const c
        (Not expr) -> Not (guess expr)
        (Or x y) -> Or (guess x) (guess y)
        (And x y) -> And (guess x) (guess y)
        where
            guess = replaceVar variable value



-- -- -- -- pravidlo unipolárneho literálu -- -- -- -- 
-- ak sa literál vyskytuje iba s jedným ohodnotením, potom všetky klauzuly obsahujúce 
-- tento literál môžeme z formuly odstrániť . Novovzniknutá formula zachováva 
-- splniteľnosť pôvodnej.

catMaybes :: [Maybe a] -> [a]
catMaybes ls = [x | Just x <- ls]

-- pomocná funkcia pre literalBoolValue, ktorá vráti Combined v prípade,
-- že sa literál vo výraze nachádza aj ako True aj ako False hodnota 
getBooleans :: [Formula] -> Char -> Maybe BoolValue
getBooleans es l = 
    let booleans = catMaybes (map go es)
    in case booleans of 
            [] -> Nothing
            bs | all (== Positive) bs -> Just Positive
               | all (== Negative) bs -> Just Negative
               | otherwise -> Just Combined
    where go = \x -> literalBoolValue x l

-- funkcia slúži pre zistenie boolean hodnoty konkrétneho literálu l
literalBoolValue :: Formula -> Char -> Maybe BoolValue
literalBoolValue (Var v) l | v == l    = Just Positive
                           | otherwise = Nothing
literalBoolValue (Not (Var v)) l | v == l    = Just Negative
                                 | otherwise = Nothing
literalBoolValue expr l =
  case expr of
    (And x y) -> getBooleans [x, y] l
    (Or x y) -> getBooleans [x, y] l
    (Not x) -> error $ "Nemá CNF formu" 
    (Const _) -> Nothing

-- pomocná funkcia pre zipovanie zoznamu literálov a zoznamu booleanov
litReplacement :: Char -> Maybe BoolValue -> Maybe (Char, Bool)
litReplacement v (Just Positive) = Just (v, True)
litReplacement v (Just Negative) = Just (v, False)
litReplacement _ _ = Nothing

-- z výrazu vyberieme všetky premenné (literály)
getLit :: Formula -> Set Char
getLit expr = 
    case expr of 
        (Var v) -> Set.singleton v
        (Not e) -> getLit e
        (And x y) -> Set.union (getLit x) (getLit y)
        (Or x y) -> Set.union (getLit x) (getLit y)
        _ -> Set.empty

literalElimination :: Formula -> Formula
literalElimination expr = replacing expr
    where ls = Set.toList (getLit expr)             -- literály
          bs = map (literalBoolValue expr) ls       -- booleany
          zipping ls bs = map (uncurry replaceVar) (catMaybes $ zipWith litReplacement ls bs)
          replacing :: Formula -> Formula
          replacing = foldl (.) id (zipping ls bs)



-- -- -- -- pravidlo jednotkového literálu -- -- -- --
-- ak klauzula obsahuje len jeden literál, potom tento literál musí 
-- nadobúdať hodnotu True. Novovzniknutá formula ma znova rovnakú 
-- splniteľnosť ako pôvodná 

-- pomocná funkcia pre mapovanie pri vyberaní samostatných literálov
unitReplacement :: Formula -> Maybe (Char, Bool)
unitReplacement l =
    case l of 
        (Var v)       -> Just (v, True)
        (Not (Var v)) -> Just (v, False)
        _             -> Nothing

-- vytvorí množinu výrazov, ktoré spolu tvoria CNF formulu
cnfSet :: Formula -> [Formula]
cnfSet (And x y) = cnfSet x ++ cnfSet y
cnfSet expr = [expr]

-- vyberie všetky samostatné literály
lonelyLit :: Formula -> [Maybe (Char, Bool)]
lonelyLit = map unitReplacement . cnfSet

unitPropagation :: Formula -> Formula 
unitPropagation expr = replacing expr
    where temp = catMaybes (lonelyLit expr)
          replacing :: Formula -> Formula
          replacing = foldl (.) id (map (uncurry replaceVar) temp)



-- -- -- -- -- -- algoritmus -- -- -- -- -- --
-- vstup si najprv pripravíme do požadovanej podoby

-- aplikovanie cnf formy, eliminácie literálov a jednotkovej propagácie
prepForDPLL :: Formula -> Formula
prepForDPLL expr = literalElimination $ cnf $ unitPropagation expr

-- zjednodušenie výrazu ak sa v ňom nachádzajú konštantné hodnoty
-- funkcia vracia buď konštatnú True/False alebo zjednodušený výraz
simplify :: Formula -> Formula
simplify (Const c) = Const c
simplify (Var v) = Var v
simplify (Not e) = 
    case simplify e of 
        (Const c)   -> Const (not c)
        e           -> Not e
simplify (Or x y) = 
    let es = filter (/= Const False) [simplify x, simplify y]
    in  
        if elem (Const True) es then Const True     -- operácia disjunkcie je pravdivá
        else case es of                             -- ak je aspoň jedna z premenných pravdivá
            [] -> Const False                       -- inak je nepravdivá
            [e] -> e
            [e1, e2] -> Or e1 e2
simplify (And x y) = 
    let es = filter (/= Const True) [simplify x, simplify y]
    in  
        if elem (Const False) es then Const False   -- operácia konjunkcia je nepravdivá 
        else case es of                             -- ak je aspoň jedna z premenných nepravdivá
            [] -> Const True                        -- inak je pravdivá
            [e] -> e
            [e1, e2] -> And e1 e2

constToVal :: Formula -> Bool 
constToVal (Const c) = c

-- DPLL algoritmus používajúci prehľadávanie s back-trackingom
-- nájde voľnú premennú, skúsi dosadiť True/False hodnotu a prehľadáva, 
-- či je fomula s hádaným ohodnotením premennej splniteľná 
dpll :: Formula -> Bool
dpll e = 
    case findVar (prepForDPLL e) of 
        Nothing -> constToVal $ simplify (prepForDPLL e)
        Just v -> 
            let trueGuess  = simplify (replaceVar v True e)
                falseGuess = simplify (replaceVar v False e)
            in dpll trueGuess || dpll falseGuess




-- -- -- SADA TESTOVACÍCH PRÍKLADOV -- -- --
test0 = dpll $ And (Var 'p') (Not (Var 'p'))                                                                            -- triviálne nesplniteľné
test1 = dpll $ Or (And (Var 'p') (Var 'q')) (Or (Var 'p') (Not (Var 'q')))                                              -- splniteľné
test2 = dpll $ Not (Or (Or (Var 'p') (Or (Var 'q') (Var 'r'))) (And (Not (Var 'p')) (Or (Var 'q') (Not (Var 'r')))))    -- nesplniteľné 
test3 = dpll $ Or (Not(Or (Not (Var 'p'))(Var 'q'))) (And (Not (Var 'q')) (Var 'r'))                                    -- splniteľné

