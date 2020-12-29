
{-# LANGUAGE OverloadedStrings #-}

module App
where
import Found
import Model
import Handler

import Develop.DatFw
import Develop.DatFw.Dispatch
import Develop.DatFw.Auth

import Network.Wai
import Data.Text

-- ---------------------------------------------------------------
-- Application initialization

-- NOTA: Canvieu al vostre fitxer de la base de dades
forumsDbName :: Text
forumsDbName = "/home/pract/LabDAT/ldatusr33/sqlite-dbs/forums.db"

makeApp :: IO Application
makeApp = do
    -- Open the database (the model state)
    db <- openDb forumsDbName
    toApp ForumsApp{ forumsDb = db }

-- ---------------------------------------------------------------
-- Main controller

instance Dispatch ForumsApp where
    dispatch = routing
            $ route ( onStatic [] ) HomeR
                [ onMethod "GET" getHomeR
                , onMethod "POST" postHomeR
                ]
            <||> route ( onStatic ["forums"] <&&> onDynamic ) ForumR
                [ onMethod1 "GET" getForumR
                , onMethod1 "POST" postForumR
                ]
            <||> route ( onStatic ["topics"] <&&> onDynamic ) TopicR
                [ onMethod1 "GET" getTopicR
                , onMethod1 "POST" postTopicR
                ]
            <||> route ( onStatic ["forums"] <&&> onDynamic <&&> onStatic ["delete"]) DeleteForumR
                [ onMethod1 "GET" getDeleteForumR
                ]
            <||> route ( onStatic ["forums"] <&&> onDynamic <&&> onStatic ["edit"]) EditForumR
                [ onMethod1 "POST" postEditForumR
                ]
            <||> route ( onStatic ["topics"] <&&> onDynamic <&&> onStatic ["delete"]) DeleteTopicR
                [ onMethod1 "GET" getDeleteTopicR
                ]
            <||> route ( onStatic ["post"] <&&> onDynamic <&&> onStatic ["delete"]) DeletePostR
                [ onMethod1 "GET" getDeletePostR
                ]
            <||> routeSub (onStatic ["auth"]) AuthR getAuth

