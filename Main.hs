{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Data.Aeson (ToJSON, toJSON, (.=), object)
import Data.GeoIP2
import Data.IP (fromHostAddress)
import Data.IP (IP(..))
import Data.Maybe (listToMaybe)
import Network.HTTP.Types (status404)
import Network.Socket (SockAddr (SockAddrInet))
import Network.Wai (remoteHost)
import Web.Scotty (get, json, scotty, header, status, text, ActionM, request, param, file, setHeader, middleware)
import Network.Wai.Middleware.Cors (simpleCors)
import System.Environment (getEnv)
import Text.Read (readMaybe)
import qualified Data.Text.Lazy as TL

newtype Result = Result GeoResult

instance ToJSON Result where
  toJSON (Result x) = object [ "city"          .= geoCity x
                             , "continentCode" .= geoContinentCode x
                             , "continent"     .= geoContinent x
                             , "countryCode"   .= geoCountryISO x
                             , "countryName"   .= geoCountry x
                             , "latitude"      .= (locationLatitude <$> geoLocation x)
                             , "longitude"     .= (locationLongitude <$> geoLocation x)
                             , "postalCode"    .= geoPostalCode x
                             , "region"        .= (fst <$> (listToMaybe $ geoSubdivisions x))
                             , "regionName"    .= (snd <$> (listToMaybe $ geoSubdivisions x))
                             ]

findIp :: ActionM (Maybe IP)
findIp = do
  forM <- header "X-Forwarded-For"
  case forM of
    Just ipTL -> return $ readMaybe $ TL.unpack ipTL
    Nothing -> do
      req <- request
      let ipA = remoteHost req
      case ipA of
        SockAddrInet _ host -> return $ Just (IPv4 $ fromHostAddress host)
        _ -> return Nothing

nope :: String -> ActionM ()
nope e = do
  status status404
  text $ TL.pack e

service :: GeoDB -> Maybe IP -> ActionM ()
service _ Nothing = nope "Couldn't figure out your IP address."
service geodb (Just ip) = do
  let geoResult = findGeoData geodb "en" ip
  case geoResult of
    Left e -> nope e
    Right x -> json (Result x)

main :: IO ()
main = do
  dbname <- getEnv "GEOIP_DB"
  geodb <- openGeoDB dbname
  scotty 3000 $ do
    middleware simpleCors
    get "/" $ do
      ipM <- findIp
      service geodb ipM
    get "/swagger.json" $ do
      setHeader "Content-Type" "application/json"
      file "swagger.json"
    get "/:ip" $ do
      ip <- param "ip"
      service geodb (readMaybe ip)

