
{-# LANGUAGE OverloadedStrings #-}

module Main
where
import System.IO
import Control.Exception

main :: IO ()
main = do
    counter <- fmap (+1) readCounter
    writeCounter counter
    putStrLn "Content-Type: text/plain"
    putStrLn ""
    putStrLn $ show counter

readCounter :: IO Int
readCounter = do
    r <- try $ do
        h <- openFile counterFilePath ReadMode
        content <- hGetLine h
        hClose h
        return $ read content
    case (r :: Either SomeException Int) of
        Right i -> return i
        Left exc -> do
            writeCounter 0
            return 0

writeCounter :: Int -> IO ()
writeCounter i = do
    h <- openFile counterFilePath WriteMode
    hPutStrLn h $ show i
    hClose h

counterFilePath = "counter.data"

