
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

editForumForm :: AForm (HandlerFor ForumsApp) NewTopic
editForumForm =
    NewTopic <$> freq textField (withPlaceholder "Introduiu el títol del forum" "Titol") Nothing
             <*> freq markdownField (withPlaceholder "Introduiu la descripció del forum" "Missatge") Nothing

newTopicForm :: AForm (HandlerFor ForumsApp) NewTopic
newTopicForm =
    NewTopic <$> freq textField (withPlaceholder "Introduiu el títol de la discussió" "Titol") Nothing
             <*> freq markdownField (withPlaceholder "Introduiu el missatge de la discussió" "Missatge") Nothing

newPostForm :: AForm (HandlerFor ForumsApp) Markdown
newPostForm =
    freq markdownField (withPlaceholder "Introduiu el missatge" "Missatge") Nothing



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
    tformw <- generateAFormPost newTopicForm
    fformw <- generateAFormPost editForumForm
    -- Return HTML content
    defaultLayout $ forumView mbuser (fid, forum, tformw, fformw)

postForumR :: ForumId -> HandlerFor ForumsApp Html
postForumR fid = do
    user <- requireAuth
    (tformr, tformw) <- runAFormPost newTopicForm
    case tformr of
        FormSuccess newTopic -> do
            now <- liftIO getCurrentTime
            -- addTopic fid uid nt now
            runDbAction $ addTopic fid (fst user) newTopic now
            redirect (ForumR fid)
        _ -> do
            redirect (ForumR fid)

getTopicR :: TopicId -> HandlerFor ForumsApp Html
getTopicR tid = do
    topic <- runDbAction (getTopic tid) >>= maybe notFound pure
    mbuser <- maybeAuth
    pformw <- generateAFormPost newPostForm
    defaultLayout $ topicView mbuser (tid, topic, pformw)

postTopicR :: TopicId -> HandlerFor ForumsApp Html
postTopicR tid = do
    user <- requireAuth
    (pformr, pformw) <- runAFormPost newPostForm
    case pformr of
        FormSuccess newPost -> do
            now <- liftIO getCurrentTime
            -- addReply fid tid uid newtext now
            topic <- runDbAction (getTopic tid) >>= maybe notFound pure
            runDbAction $ addReply (tdForumId topic) tid (fst user) newPost now
            redirect (TopicR tid)
        _ -> do
            topic <- runDbAction (getTopic tid) >>= maybe notFound pure
            defaultLayout $ topicView (Just user) (tid, topic, pformw)

getDeleteForumR :: ForumId -> HandlerFor ForumsApp Html
getDeleteForumR fid = do
    user <- requireAuth
    -- deleteForum fid
    runDbAction $ deleteForum fid
    redirect HomeR

getDeleteTopicR :: TopicId -> HandlerFor ForumsApp Html
getDeleteTopicR tid = do
    user <- requireAuth
    -- deleteTopic fid tid
    topic <- runDbAction (getTopic tid) >>= maybe notFound pure
    let fid = tdForumId topic
    runDbAction $ deleteTopic fid tid
    redirect (ForumR fid)

getDeletePostR :: PostId -> HandlerFor ForumsApp Html
getDeletePostR pid = do
    user <- requireAuth
    post <- runDbAction (getPost pid) >>= maybe notFound pure
    let tid = pdTopicId post
    topic <- runDbAction (getTopic tid) >>= maybe notFound pure
    -- deletePost fid tid pid
    runDbAction $ deletePost (tdForumId topic) tid pid
    redirect (TopicR tid)

postEditForumR :: ForumId -> HandlerFor ForumsApp Html
postEditForumR fid = do
    user <- requireAuth
    (fformr, fformw) <- runAFormPost editForumForm
    case fformr of
        FormSuccess editForumContent -> do
            -- editForum fid nfTitle nfDescriptio
            runDbAction $ editForum fid (ntSubject editForumContent) (ntMessage editForumContent)
            redirect (ForumR fid)
        _ -> do
            redirect (ForumR fid)