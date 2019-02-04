# Steps needed to Build (On ghc-8 branch)

## Dependencies
- had to install:
  - ncurses5
  - postgresql
  - libtinfo-dev

## Other Steps
- create a file at Carnap-Server/SecureStrings.hs containing the following
`````
module SecureStrings where
import Data.Text

googleSecret :: Text
googleSecret = ""

googleApiKey :: Text
googleApiKey = ""
`````

- replaced static/ghcjs folder with compressed folder from issue page.
- create the ../dataroot and ../Carnap-Book/cache folders.
- build with Command:
  ```APPROOT='http://localhost:3000' DATAROOT="../dataroot" BOOKROOT="../Carnap-Book/" stack build --ghc-options -DDEVELOPMENT```
