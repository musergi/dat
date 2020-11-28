
{-# LANGUAGE OverloadedStrings #-}

module Model
    ( module Model
    , Connection, openDb, closeDb
    , runDbTran, DbM, Key(..)
    )
where
import Db

import Data.Text
import Data.Monoid
import Data.Int
import Data.Time

minTitleLen :: Int
minTitleLen = 8
minPostLen :: Int
minPostLen = 20

-- ---------------------------------------------------------------
-- Field: Markdown

newtype Markdown = Markdown { getMdText :: Text }
        deriving (Show)

instance FromField Markdown where
  fromField f = Markdown <$> fromField f

instance ToField Markdown where
  toField (Markdown t) = toField t


-- ---------------------------------------------------------------
-- Table: UserD

type UserId = Key UserD

data UserD = UserD
        { udName :: Text
        , udPassword :: Text
        , udIsAdmin :: Bool
        }
        deriving (Show)

instance DbEntity UserD where
    tableName _ = "users"
    columnNames _ = ["name","password", "isAdmin"]

instance FromRow UserD where
  fromRow = UserD <$> field <*> field <*> field

instance ToRow UserD where
  toRow (UserD f1 f2 f3) = toRow (f1, f2, f3)


getUser :: UserId -> DbM (Maybe UserD)
getUser uid = do
    get uid

getUserByName :: Text -> DbM (Maybe (UserId, UserD))
getUserByName name = do
    us <- select (\ _ u -> name == udName u)
    case us of
        u : _ -> pure $ Just u
        [] -> pure Nothing


-- ---------------------------------------------------------------
-- Table: ForumD

type ForumId = Key ForumD

data ForumD = ForumD
        { fdCategory :: Text
        , fdTitle :: Text
        , fdDescription :: Markdown
        , fdModeratorId :: UserId
        , fdCreated :: UTCTime         -- Forum creation time

        , fdTopicCount :: Int
        , fdPostCount :: Int
        , fdLastPostId :: Maybe PostId
        }
        deriving (Show)

instance DbEntity ForumD where
    tableName _ = "forums"
    columnNames _ = ["category","title","description","moderatorId","created"
                    ,"topicCount","postCount","lastPostId"
                    ]

instance FromRow ForumD where
  fromRow = ForumD <$> field <*> field <*> field <*> field <*> field
                  <*> field <*> field <*> field

instance ToRow ForumD where
  toRow (ForumD f1 f2 f3 f4 f5 f6 f7 f8) = toRow (f1, f2, f3, f4, f5, f6, f7, f8)


getForumList :: DbM [(ForumId, ForumD)]
getForumList =
    select (const $ const True)

getForum :: ForumId -> DbM (Maybe ForumD)
getForum fid = do
    get fid

data NewForum = NewForum { nfTitle :: Text, nfDescription :: Markdown, nfModeratorId :: UserId }

addForum :: NewForum -> UTCTime -> DbM ForumId
addForum nf now = do
    add $ ForumD { fdCategory = ""
                 , fdTitle = nfTitle nf
                 , fdDescription = nfDescription nf
                 , fdModeratorId = nfModeratorId nf
                 , fdCreated = now
                 , fdTopicCount = 0
                 , fdPostCount = 0
                 , fdLastPostId = Nothing
                 }

deleteForum :: ForumId -> DbM ()
deleteForum fid = do
    ts <- getTopicList fid
    mapM_ (deleteTopic fid) (fst <$> ts)
    Db.delete fid


-- ---------------------------------------------------------------
-- Table: TopicD (aka thread)

type TopicId = Key TopicD

data TopicD = TopicD
        { tdForumId :: ForumId
        , tdSubject :: Text
        , tdUserId :: UserId
        , tdStarted :: UTCTime

        , tdPostCount :: Int
        , tdFirstPostId :: Maybe PostId
        , tdLastPostId :: Maybe PostId
        ---, tdLastPostNum :: Int           -- 0 for the first post (the topic starter)
        }
        deriving (Show)

instance DbEntity TopicD where
    tableName _ = "topics"
    columnNames _ = ["forumId","subject","userId","started","postCount","firstPostId","lastPostId"]

instance FromRow TopicD where
  fromRow = TopicD <$> field <*> field <*> field <*> field <*> field <*> field <*> field

instance ToRow TopicD where
  toRow (TopicD f1 f2 f3 f4 f5 f6 f7) = toRow (f1, f2, f3, f4, f5, f6, f7)

getTopicList :: ForumId -> DbM [(TopicId, TopicD)]
getTopicList fid =
    ---selectOrder (const $ (fid==) . tdForumId) tdLastPosted
    select (const $ (fid==) . tdForumId)

getTopic :: TopicId -> DbM (Maybe TopicD)
getTopic tid = do
    get tid

data NewTopic = NewTopic { ntSubject :: Text, ntMessage :: Markdown }

addTopic :: ForumId -> UserId -> NewTopic -> UTCTime -> DbM (TopicId, PostId)
addTopic fid uid nt now = do
    -- Create the new topic and get its identifier
    let topic0 = TopicD
                { tdForumId = fid
                , tdSubject = ntSubject nt
                , tdUserId = uid
                , tdStarted = now
                , tdPostCount = 1
                , tdFirstPostId = Nothing
                , tdLastPostId = Nothing
                }
    tid <- add topic0
    -- Create the topic's first post (the question) and get its identifier
    pid <- add $ PostD tid uid now (ntMessage nt)
    -- Set the topic's last post to the identifier of the created post
    set tid $ topic0{ tdFirstPostId = Just pid, tdLastPostId = Just pid }
    -- Update the forum's summary information
    update fid $
        \ forum -> forum{ fdTopicCount = fdTopicCount forum + 1
                        , fdPostCount = fdPostCount forum + 1
                        , fdLastPostId = Just pid
                        }
    pure (tid, pid)

deleteTopic :: ForumId -> TopicId -> DbM ()
deleteTopic fid tid = do
    posts <- getPostList tid
    mapM_ (deletePost fid tid) (fst <$> posts)
    update fid $ \ forum -> forum{ fdTopicCount = fdTopicCount forum - 1 }
    Db.delete tid


-- ---------------------------------------------------------------
-- Table: PostD

type PostId = Key PostD

data PostD = PostD
        { pdTopicId :: TopicId
        , pdUserId :: UserId
        , pdPosted :: UTCTime
        ---, pdNum :: Int                   -- 0 for the first post (the topic starter)
        , pdMessage :: Markdown
        }
        deriving (Show)

instance DbEntity PostD where
    tableName _ = "posts"
    columnNames _ = ["topicId","userId","posted","message"]

instance FromRow PostD where
  fromRow = PostD <$> field <*> field <*> field <*> field

instance ToRow PostD where
  toRow (PostD f1 f2 f3 f4) = toRow (f1, f2, f3, f4)

getPostList :: TopicId -> DbM [(PostId, PostD)]
getPostList tid =
    selectOrder (const $ (tid==) . pdTopicId) pdPosted

getPost :: PostId -> DbM (Maybe PostD)
getPost pid = do
    get pid

addReply :: ForumId -> TopicId -> UserId -> Markdown -> UTCTime -> DbM PostId
addReply fid tid uid newtext now = do
    -- Create the new post
    pid <- add $ PostD tid uid now newtext
    -- Update the topic's summary information
    update tid $
        \ topic -> topic{ tdPostCount = tdPostCount topic + 1
                        , tdLastPostId = Just pid
                        }
    -- Update the forum's summary information
    update fid $
        \ forum -> forum{ fdPostCount = fdPostCount forum + 1
                        , fdLastPostId = Just pid
                        }
    pure pid

deletePost :: ForumId -> TopicId -> PostId -> DbM ()
deletePost fid tid pid = do
    update fid $
        \ forum -> forum{ fdPostCount = fdPostCount forum - 1
                        , fdLastPostId = if Just pid == fdLastPostId forum then Nothing else fdLastPostId forum
                        }
    update tid $
        \ topic -> topic{ tdPostCount = tdPostCount topic - 1
                        , tdFirstPostId = if Just pid == tdFirstPostId topic then Nothing else tdFirstPostId topic
                        , tdLastPostId = if Just pid == tdLastPostId topic then Nothing else tdLastPostId topic
                        }
    Db.delete pid

