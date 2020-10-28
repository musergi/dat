
{-# LANGUAGE OverloadedStrings #-}

module Handler
    -- Exporta les seguents declaracions d'aquest modul
    ( Handler, dispatchHandler
    , HandlerResponse, respHtml, respRedirect, respError
    , getMethod, onMethod
    , getSession, setSession, deleteSession
    , postParams, lookupPostParams, lookupPostParam
    )
where
import qualified Network.Wai as W
import qualified Network.HTTP.Types as W
import qualified Web.Cookie as W

import qualified Text.Blaze.Html5 as H
import           Text.Blaze.Html.Renderer.Utf8

import           Data.Text (Text)
import qualified Data.Text as T
import           Data.Text.Encoding as T
import qualified Data.ByteString as B
import           Data.ByteString.Builder
import qualified Data.ByteString.Lazy as BL
import           Data.Maybe
import           Data.Monoid
import           Control.Monad
import           Control.Applicative
import           Control.Monad.IO.Class
import           Text.Read

-- ****************************************************************

-- Tipus correponent al monad 'Handler'.
-- El context d'un Handler compren:
--      L'argument Request que permet obtenir informacio sobre la peticio.
--      L'estat del Handler (argument i resultat de les operacions).
newtype Handler a =
    HandlerC { runHandler :: W.Request -> HandlerState -> IO (a, HandlerState) }

-- HandlerState compren:
--      'Cache' dels parametres de la peticio.
--      L'estat de la sessio que s'obte de les corresponents 'cookies'.
--        Aquest estat de sessio es una llista de parelles nom-valor.
data HandlerState =
    HandlerStateC { hsQuery :: Maybe [(Text, Text)], hsSession :: [(Text, Text)] }

-- Funcions auxiliars per modificar l'estat del handler
hsSetQuery :: Maybe [(Text, Text)] -> HandlerState -> HandlerState
hsSetQuery q (HandlerStateC _ s) = HandlerStateC q s
hsSetSession :: [(Text, Text)] -> HandlerState -> HandlerState
hsSetSession s (HandlerStateC q _) = HandlerStateC q s

instance Functor Handler where
    -- tipus en aquesta instancia:
    --      fmap :: (a -> b) -> Handler a -> Handler b
    fmap f (HandlerC h) = HandlerC $ \ req st0 -> do
        -- Monad IO:
        (x, st1) <- h req st0
        pure (f x, st1)

instance Applicative Handler where
    -- tipus en aquesta instancia:
    --      pure  :: a -> Handler a
    --      (<*>) :: Handler (a -> b) -> Handler a -> Handler b
    pure x =
        HandlerC $ \req s0 -> pure (x, s0)
    HandlerC hf <*> HandlerC hx =
        HandlerC $ \req s0 -> do 
            -- Monad IO:
            (f, s1) <- hf req s0
            (x, s2) <- hx req s1
            pure (f x, s2)

instance Monad Handler where
    -- tipus en aquesta instancia:
    --      (>>=) :: Handler a -> (a -> Handler b) -> Handler b
    HandlerC hx >>= f = 
        HandlerC $ \req s0 -> do
            -- Monad IO:
            (x, s1) <- hx req s0
            let HandlerC hy = f x
            (y, s2) <- hy req s1
            return (y, s2)


-- class MonadIO m: Monads m in which IO computations may be embedded.
-- The method 'liftIO' lifts a computation from the IO monad.
instance MonadIO Handler where
    -- tipus en aquesta instancia:
    --      liftIO :: IO a -> Handler a
    liftIO io = HandlerC $ \ _ st0 -> do
        x <- io
        pure (x, st0)

-- ****************************************************************
-- Aquestes funcions no s'exporten pero son utils en les implementacions
-- de les funcions exportades.

-- Obte informació de la peticio
asksRequest :: (W.Request -> a) -> Handler a
asksRequest f = HandlerC $ \ req st0 ->
    pure (f req, st0)

-- Obte informació de l'estat del handler
getsHandlerState :: (HandlerState -> a) -> Handler a
getsHandlerState f =
    HandlerC $ \req s0 -> return (f s0, s0)

-- Modifica l'estat del handler
modifyHandlerState :: (HandlerState -> HandlerState) -> Handler ()
modifyHandlerState f =
    HandlerC $ \req s0 -> return ((), f s0)

-- ****************************************************************

-- Tipus que ha de tenir el resultat del handler que se li passa a 'dispatchHandler'.
data HandlerResponse =
        HRHtml H.Html           -- Resposta normal. Parametre: Contingut HTML.
      | HRRedirect Text         -- Redireccio. Parametre: URL.
      | HRError W.Status Text   -- Resposta anormal. Parametres: Codi d'estat HTTP i missatge.

-- 'dispatchHandler' converteix (adapta) un 'Handler' a una aplicacio WAI,
-- realitzant els passos seguents:
--      Obte l'estat inicial (st0) del handler amb una sessio inicial a partir
--        de les cookies rebudes en la peticio WAI.
--      Executa el handler passant-li la peticio i l'estat inicial.
--      Amb l'execucio del handler s'obte el parell format
--        pel resultat del handler (res) i l'estat final (st1).
--      Construeix la corresponent resposta WAI i l'envia.
--        La resposta WAI depen del nou estat de sessio en st1.
-- El tipus 'Application' esta definit en el modul 'Network.Wai' com:
--      type Application = Request -> (Response -> IO ResponseReceived) -> IO ResponseReceived
dispatchHandler :: Handler HandlerResponse -> W.Application
dispatchHandler handler req respond = do
    -- Monad IO:
    let st0 = HandlerStateC{ hsQuery = Nothing, hsSession = requestSession req }
    (res, st1) <- runHandler handler req st0
    let scValue = mkSetCookieValue $ hsSession st1
        wairesp = case res of
            HRHtml html ->
                let headers = [ ("Content-Type", mimeHtml)
                              , ("Set-Cookie", scValue) ]
                in W.responseBuilder W.ok200 headers (renderHtmlBuilder html)
            HRRedirect url ->
                let headers = [ ("Location", T.encodeUtf8 url)
                              , ("Content-Type", mimeText)
                              , ("Set-Cookie", scValue) ]
                in W.responseBuilder W.seeOther303 headers (T.encodeUtf8Builder "Redirect")
            HRError status msg ->
                let headers = [ ("Content-Type", mimeText) ]
                in W.responseBuilder status headers (T.encodeUtf8Builder msg)
    respond wairesp

-- Els constructors de HandlerResponse no s'exporten.
-- S'exporten en canvi les funcions seguents que obtenen simples handlers que retornen
-- els diferents tipus de resposta:

respHtml :: H.Html -> Handler HandlerResponse
respHtml html = pure $ HRHtml html

respRedirect :: Text -> Handler HandlerResponse
respRedirect url = pure $ HRRedirect url

respError :: W.Status -> Text -> Handler HandlerResponse
respError status msg = pure $ HRError status msg


-- ****************************************************************

-- Obte el metode HTTP de la peticio
getMethod :: Handler W.Method
getMethod = asksRequest W.requestMethod

-- Obte el metode HTTP de la peticio
onMethod :: [(W.Method, Handler HandlerResponse)] -> Handler HandlerResponse
onMethod alts = do
    -- Monad Handler:
    method <- getMethod
    case lookup method alts of
        Just h -> h
        Nothing -> respError W.methodNotAllowed405 "Invalid method"

-- Obte el valor de l'atribut de sessio amb el nom indicat.
-- Retorna Nothing si l'atribut indicat no existeix o no te la sintaxis adequada.
getSession :: Read a => Text -> Handler (Maybe a)
getSession name = do
    session <- getsHandlerState hsSession
    pure $ maybe Nothing (readMaybe . T.unpack) $ lookup name session

-- Fixa l'atribut de sessio amb el nom i valor indicats.
setSession :: Show a => Text -> a -> Handler ()
setSession name value = do
    session <- getsHandlerState hsSession
    let newsession = (name, T.pack $ show value) : filter ((name /=) . fst) session
    modifyHandlerState (hsSetSession newsession)

-- Elimina l'atribut de sessio amb el nom indicat.
deleteSession :: Text -> Handler ()
deleteSession name = do
    session <- getsHandlerState hsSession
    let newsession = filter ((name /=) . fst) session
    modifyHandlerState (hsSetSession newsession)

-- Obte els valor associat al parametre de la peticio amb el nom indicat.
lookupPostParam :: Text -> Handler (Maybe Text)
lookupPostParam name = do
    vals <- lookupPostParams name
    case vals of
        [] -> pure Nothing
        (v:_) -> pure (Just v)

-- Obte els valors associats al parametre de la peticio amb el nom indicat.
lookupPostParams :: Text -> Handler [Text]
lookupPostParams name = do
    -- Monad Handler:
    mbparams <- postParams
    case mbparams of
        Just params -> -- params es una llista de parelles de tipus (Text, Text)
            -- (A completar per l'estudiant).
            -- Caldra obtenir tots els valors (segon component) de les parelles que tenen el nom (primer component) igual al indicat.
            -- NOTA: Useu les funcions
            --   fst :: (a, b) -> a
            --   snd :: (a, b) -> b
            --   filter :: (a -> Bool) -> [a] -> [a]
            return (map snd (filter (\param -> fst param == name) params)) -- Filter by fst, map snd
        Nothing ->
            -- El contingut de la peticio no es un formulari. No hi ha valors.
            pure []

-- Obte tots els parametres (parelles (nom,valor)) del contingut de la peticio.
-- Retorna Nothing si el contingut de la peticio no es un formulari.
postParams :: Handler (Maybe [(Text, Text)])
postParams = do
    -- Si previament ja s'havien obtingut els parametres (i guardats en l'estat del handler)
    -- aleshores es retornen aquests, evitant tornar a llegir el contingut de la peticio.
    cache <- getsHandlerState hsQuery
    case cache of
        Just query ->
            pure $ Just query
        Nothing -> do
            req <- asksRequest id
            if lookup W.hContentType (W.requestHeaders req) == Just "application/x-www-form-urlencoded" then do
                query <- liftIO $ parsePostQuery <$> getAllBody req
                modifyHandlerState (hsSetQuery $ Just query)
                pure $ Just query
            else
                pure Nothing

-- ****************************************************************
-- Funcions internes (utilitats no exportades)

mimeText :: B.ByteString
mimeText = "text/plain;charset=UTF-8"

mimeHtml :: B.ByteString
mimeHtml = "text/html;charset=UTF-8"

-- Obte l'estat de sessio a partir de la corresponent 'cookie' de la peticio.
requestSession :: W.Request -> [(Text, Text)]
requestSession req =
    let mbvalue = do -- Monad Maybe
            cookieHeader <- lookup "Cookie" (W.requestHeaders req)
            session <- lookup (T.encodeUtf8 "session") (W.parseCookies cookieHeader)
            readMaybe $ T.unpack $ T.decodeUtf8 session
    in maybe [] id mbvalue

-- Funcio auxiliar que obte el valor de la 'cookie' resultant a partir de l'estat de sessio.
mkSetCookieValue :: [(Text, Text)] -> B.ByteString
mkSetCookieValue session =
    let setCookie = W.defaultSetCookie { W.setCookieName = T.encodeUtf8 "session"
                                       , W.setCookieValue = T.encodeUtf8 $ T.pack $ show session
                                       }
    in BL.toStrict $ toLazyByteString $ W.renderSetCookie setCookie

parsePostQuery :: B.ByteString -> [(Text, Text)]
parsePostQuery content =
    decodepair <$> W.parseSimpleQuery content
    where
        decodepair (n, v) = (T.decodeUtf8 n, T.decodeUtf8 v)

getAllBody :: W.Request -> IO B.ByteString
getAllBody req = do
    b <- W.requestBody req
    if B.null b then pure B.empty
    else do
        bs <- getAllBody req
        pure $ b <> bs

