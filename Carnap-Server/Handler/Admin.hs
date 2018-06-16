module Handler.Admin where

import Import
import Util.Data
import Util.Database
import Yesod.Form.Bootstrap3
import Yesod.Form.Jquery
import Text.Blaze.Html (toMarkup)
import Data.Time
import System.FilePath
import System.Directory (getDirectoryContents,removeFile, doesFileExist)

postAdminR :: Handler Html
postAdminR = do allUserData <- map entityVal <$> (runDB $ selectList [] [])
                musers <- mapM (\x -> runDB (get x)) (map userDataUserId  allUserData)
                ((upgraderslt,upgradeWidget),enctypeUpgrade) <- runFormPost (upgradeToInstructor $ catMaybes musers)
                case upgraderslt of 
                     (FormSuccess ident) -> do 
                            success <- runDB $ do imd <- insert InstructorMetadata
                                                  muent <- getBy $ UniqueUser ident
                                                  mudent <- case entityKey <$> muent of
                                                                Just uid -> getBy $ UniqueUserData uid
                                                                Nothing -> return Nothing
                                                  case entityKey <$> mudent of 
                                                       Nothing -> return False
                                                       Just udid -> do update udid [UserDataInstructorId =. Just imd]
                                                                       return True
                            if success then setMessage $ "user " ++ (toMarkup ident) ++ " upgraded to instructor"
                                       else setMessage $ "couldn't upgrade user " ++ (toMarkup ident) ++ " to instructor"
                     (FormFailure s) -> setMessage $ "Something went wrong: " ++ toMarkup (show s)
                     FormMissing -> setMessage "Submission data incomplete"
                redirect AdminR --XXX: redirect here to make sure changes are visually reflected

getAdminR :: Handler Html
getAdminR = do allUserData <- map entityVal <$> (runDB $ selectList [] [])
               let allUids = (map userDataUserId  allUserData)
               courses <- mapM getCoursesWithEnrollment allUserData
               musers <- mapM (\x -> runDB (get x)) allUids
               let users = catMaybes musers
               usertable <- usersWidget users allUserData courses
               (upgradeWidget,enctypeUpgrade) <- generateFormPost (upgradeToInstructor users)
               defaultLayout [whamlet|
                              <div.container>
                                  <p> Wecome to Admin
                                  ^{usertable}
                                  <form method=post enctype=#{enctypeUpgrade}>
                                      ^{upgradeWidget}
                                       <div.form-group>
                                           <input.btn.btn-primary type=submit value="upgrade">
                             |]
    where getCoursesWithEnrollment ud = case userDataInstructorId ud of 
                                            Just iid -> do courseEnt <- runDB $ selectList [CourseInstructor ==. iid] []
                                                           enrollments <- mapM (\c -> runDB $ selectList [UserDataEnrolledIn ==. Just (entityKey c)] []) courseEnt
                                                           return $ zip courseEnt enrollments

                                            Nothing -> return []

upgradeToInstructor users = renderBootstrap3 BootstrapBasicForm $
                                areq (selectFieldList userIdents) (bfs ("Upgrade User to Instructor" :: Text)) Nothing
        where userIdents = let idents = map userIdent users in zip idents idents

usersWidget :: [User] -> [UserData] -> [[(Entity Course,[Entity UserData])]] -> HandlerT App IO Widget
usersWidget us ud cs = do let usersAndData = zip3 us ud cs
                          return [whamlet|
                                  <div.card style="margin-bottom:20px">
                                      <div.card-header>
                                          All Users
                                      <div.card-block>
                                          <table.table.table-striped>
                                              <thead>
                                                  <th> Identifier
                                                  <th> Name
                                                  <th> Instructor?
                                                  <th> Courses
                                                  <th> Total Students
                                              <tbody>
                                                  $forall (u,UserData fn ln _ mid _,clist) <- usersAndData
                                                      <tr>
                                                          <td>
                                                              <a href=@{UserR (userIdent u)}>#{userIdent u}
                                                          <td>
                                                              #{ln}, #{fn}
                                                          $maybe _ <- mid
                                                              <td>yes
                                                              <td>#{length clist}
                                                              <td>#{length (concat (map snd clist))}
                                                          $nothing
                                                              <td>no
                                                              <td>N/A
                                                              <td>N/A
                        |]

