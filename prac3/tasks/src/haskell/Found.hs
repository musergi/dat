
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TemplateHaskell #-}

module Found
where
import Model

import Develop.DatFw
import Develop.DatFw.Template
import Develop.DatFw.Auth
import Develop.DatFw.Auth.Hardcoded

import Data.Text (Text)


-- ****************************************************************
-- Definicions basiques de l'aplicacio o lloc Tasks:
--      Tipus Tasks (informacio global del lloc): conte la connexio amb la base de dades
--      Tipus de les rutes de Tasks
--      Instancia de WebApp (configuracio del lloc) per a Tasks
--      Instancia de WebAuth (configuracio del subsistema d'autenticacio Auth) per a Tasks

-- NOTA: Veieu en <https://en.wikibooks.org/wiki/Haskell/More_on_datatypes#Named_Fields_(Record_Syntax)>
-- una breu introducció a la sintaxis dels registres Haskell

data Tasks = Tasks { tasksDb :: TasksDb }

type TasksRoute = Route Tasks

instance RenderRoute Tasks where
    data Route Tasks =
          HomeR
        | AuthR (Route Auth)

    renderRoute HomeR   = ([], [])
    renderRoute (AuthR authr) = let (path, qs) = renderRoute authr in ("auth" : path, qs)


instance WebApp Tasks where
    defaultLayout wdgt = do
        page <- widgetToPageContent wdgt
        mbuser <- maybeAuthId
        mbmsg <- getMessage
        applyUrlRenderTo $(htmlTemplFile "src/templates/default-layout.html")
    authRoute _ =
        Just $ AuthR LoginR

instance WebAuth Tasks where
    type AuthId Tasks = Text
    loginDest _ = HomeR
    logoutDest _ = HomeR
    authPlugins _ = [hardcodedPlugin]
    authenticate (Creds plugin authid extra) =
        pure $ Authenticated authid

instance WebAuthHardcoded Tasks where
    validatePassword name password =
        pure $ name /= "" && name == password

