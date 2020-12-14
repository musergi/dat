
{-# LANGUAGE OverloadedStrings #-}

module Main
where
import App

import Network.Wai
import Network.Wai.Handler.CGI (run)

import Control.Exception

-- ****************************************************************

main :: IO ()
main = do
    -- La funcio 'makeApp' (definida en el modul App) construeix una aplicacio WAI
    -- a partir d'una aplicacio de tipus Tasks (instancia de WebApp de DatFw)
    r <- try makeApp
    case r of
        Right app -> do
            -- CGI adapter
            run app
        Left exc -> do
            -- Exception on initialization
            putStrLn "Status: 500 Internal Server Error"
            putStrLn "Content-Type: text/plain"
            putStrLn ""
            putStrLn "Exception on initialization (while excution of 'makeApp'): "
            putStrLn $ "    " ++ show (exc :: SomeException)

