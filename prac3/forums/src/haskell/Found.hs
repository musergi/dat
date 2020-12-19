
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TemplateHaskell #-}

module Found
where
import Model

import Develop.DatFw
import Develop.DatFw.Handler
import Develop.DatFw.Widget
import Develop.DatFw.Template
import Develop.DatFw.Auth
import Develop.DatFw.Auth.Hardcoded

import Data.Text (Text)
import qualified Data.Text.Encoding as T
import Data.ByteString.Builder
import Data.Int
import Data.Time
import Control.Monad.IO.Class   -- imports liftIO


-- ---------------------------------------------------------------
-- Definició dels tipus del site ForumsApp i de les corresponents rutes.

data ForumsApp = ForumsApp { forumsDb :: Connection }


instance RenderRoute ForumsApp where
    data Route ForumsApp =
                  HomeR | ForumR ForumId | TopicR TopicId | DeletePostR PostId
                | DeleteTopicR TopicId | DeleteForumR ForumId
                | AuthR (Route Auth)

    renderRoute HomeR   = ([], [])
    renderRoute (ForumR tid) = (["forums",toPathPiece tid], [])
    renderRoute (TopicR qid) = (["topics",toPathPiece qid], [])
    renderRoute (DeleteForumR fid) = (["forums",toPathPiece fid,"delete"], [])
    renderRoute (DeleteTopicR tid) = (["topics",toPathPiece tid,"delete"], [])
    renderRoute (DeletePostR pid) = (["post",toPathPiece pid,"delete"], [])
    renderRoute (AuthR authr) = let (path,qs) = renderRoute authr in ("auth":path, qs)

-- Nota: Els tipus ForumId, TopicId i PostId són alias de 'Key ...' (veieu el model)
instance PathPiece (Key a) where
    toPathPiece (Key k) = showToPathPiece k
    fromPathPiece p = Key <$> readFromPathPiece p


runDbAction :: (MonadHandler m, HandlerSite m ~ ForumsApp) => DbM a -> m a
runDbAction f = do
    conn <- getsSite forumsDb
    liftIO $ runDbTran conn f

-- ---------------------------------------------------------------
-- Instancia de WebApp (configuracio del lloc) per a ForumsApp.

instance WebApp ForumsApp where
    defaultLayout wdgt = do
        page <- widgetToPageContent wdgt
        mbmsg <- getMessage
        mbuser <- fmap (fmap snd) maybeAuth
        applyUrlRenderTo $(htmlTemplFile "src/templates/default-layout.html")
    authRoute _ =
        Just $ AuthR LoginR     -- get the login link

-- ---------------------------------------------------------------
-- Instancia de WebAuth (configuracio del subsistema d'autenticacio Auth) per a ForumsApp.

instance WebAuth ForumsApp where
    type AuthId ForumsApp = UserId
    loginDest _ = HomeR
    logoutDest _ = HomeR
    authPlugins _ = [hardcodedPlugin]
    authenticate (Creds plugin name extra) = do
        mbuser <- runDbAction $ getUserByName name
        case mbuser of
            Nothing -> pure $ ServerError "User not in DB"
            Just (uid, _) -> pure $ Authenticated uid
    redirectToReferer _ = True

instance WebAuthPersist ForumsApp where
    type AuthEntity ForumsApp = UserD
    getAuthEntity uid = runDbAction $ getUser uid

instance WebAuthHardcoded ForumsApp where
    validatePassword name password = do
        mbuser <- runDbAction $ getUserByName name
        case mbuser of
            Nothing -> pure False
            Just (_, user) -> pure $ password == udPassword user

