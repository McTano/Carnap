# Steps needed to Build (On ghc-8 branch)

## Dependencies
- had to install:
  - ncurses5
  - postgresql
  - libtinfo-dev

## Other Steps
- The app will not compile because SecureStrings.hs is not present, even though it does not get used in development mode.
- To get around this, create a file at Carnap-Server/SecureStrings.hs containing the following
`````
module SecureStrings where
import Data.Text

googleSecret :: Text
googleSecret = ""

googleApiKey :: Text
googleApiKey = ""
`````

- replaced static/ghcjs folder with compressed folder from issue page.
- create the /dataroot and /Carnap-Book/cache folders.
- build with Command:
[Note, this seems to work without setting the env variables at the front of the command]
  ```
  APPROOT='http://localhost:3000' DATAROOT="../dataroot" BOOKROOT="../Carnap-Book/" stack build --ghc-options -DDEVELOPMENT
  ```
  to run server, do:
  `cd Carnap-server`
  `APPROOT="http://localhost:3000" DATAROOT="../dataroot" BOOKROOT="../Carnap-Book" stack exec Carnap-Server`ntpun

Then vist localhost:3000 in your browser.
