
{-# LANGUAGE OverloadedStrings #-}

module Handler
where
import View
import Found
import Model

import Develop.DatFw
import Develop.DatFw.Handler
import Develop.DatFw.Template
import Develop.DatFw.Widget
import Develop.DatFw.Auth
import Develop.DatFw.Form
import Develop.DatFw.Form.Fields
import Text.Blaze

import Data.Text as T
import Control.Monad.IO.Class   -- imports liftIO
import Data.Time

-- ---------------------------------------------------------------

markdownField :: Field (HandlerFor ForumsApp) Markdown
markdownField = checkMap
        (\ t -> if T.length t < 20 then Left "Text massa curt" else Right (Markdown t))
        getMdText
        textareaField

---------------------------------------------------------------------

newForumForm :: AForm (HandlerFor ForumsApp) NewForum
newForumForm =
    NewForum <$> freq textField (withPlaceholder "Introduiu el títol del fòrum" "Titol") Nothing
             <*> freq markdownField (withPlaceholder "Introduiu la descripció del fòrum" "Descripció") Nothing
             <*> (fst <$> freq (checkMMap checkUserExists (udName . snd) textField)
                   (withPlaceholder "Introduiu el nom de l'usuari moderador" "Nom del moderador")
                   Nothing)

newTopicForm :: AFor (HandlerFor ForumsApp) NewTopic
newTopicForm =
    NewTopic <$> freq textField (withPlaceholder "Introduiu el títol de la discussió" "Titol") Nothing
             <*> freq markdownField (withPlaceholder "Introduiu el missatge de la discussió" "Missatge") Nothing

checkUserExists :: Text -> HandlerFor ForumsApp (Either Text (UserId, UserD))
checkUserExists uname = do
    mbu <- runDbAction $ getUserByName uname
    pure $ maybe (Left "L'usuari no existeix") Right mbu

getHomeR :: HandlerFor ForumsApp Html
getHomeR = do
    -- Get authenticated user
    mbuser <- maybeAuth
    -- Get a fresh form
    fformw <- generateAFormPost newForumForm
    -- Return HTML content
    defaultLayout $ homeView mbuser fformw

postHomeR :: HandlerFor ForumsApp Html
postHomeR = do
    user <- requireAuth
    (fformr, fformw) <- runAFormPost newForumForm
    case fformr of
        FormSuccess newtheme -> do
            now <- liftIO getCurrentTime
            runDbAction $ addForum newtheme now
            redirect HomeR
        _ ->
            defaultLayout $ homeView (Just user) fformw


getForumR :: ForumId -> HandlerFor ForumsApp Html
getForumR fid = do
    -- Get requested forum from data-base.
    -- Short-circuit (responds immediately) with a 'Not found' status if forum don't exist
    forum <- runDbAction (getForum fid) >>= maybe notFound pure
    mbuser <- maybeAuth
    -- Other processing (forms, ...)
    -- ... A completar per l'estudiant
    tformw <- runAFormPost newTopicForm
    -- Return HTML content
    defaultLayout $ forumView mbuser (fid, forum, tformw)

postForumR :: ForumId -> HandlerFor ForumsApp Html
postForumR tid = do
    fail "A completar per l'estudiant"


getTopicR :: TopicId -> HandlerFor ForumsApp Html
getTopicR tid = do
    fail "A completar per l'estudiant"

postTopicR :: TopicId -> HandlerFor ForumsApp Html
postTopicR tid = do
    fail "A completar per l'estudiant"

