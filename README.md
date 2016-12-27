## About

Geode is a simple Web frontend for [MaxMind][maxmind]'s [GeoIP2
City][geoip2-city] database.

## Setup

Purchase a [*GeoIP2 City* database][geoip2-city], or grab a free
[*GeoLite2 City* database][geolite2] from MaxMind:

```
$ curl -s http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz | \
  gunzip > GeoIP2-City.mmdb
```

Prep Cabal for building/running Geode:

```
$ cabal sandbox init
$ cabal install -j --only-dependencies
```

## Usage

Fire up Geode:

```
$ cabal run
Running geode...
Setting phasers to stun... (port 3000) (ctrl-c to quit)
```

Try it out:

```
$ curl -s localhost:3000/8.8.8.8
{
  "regionName": "California",
  "latitude": 37.386,
  "postalCode": "94035",
  "city": "Mountain View",
  "countryName": "United States",
  "countryCode": "US",
  "region": "CA",
  "longitude": -122.0838,
  "continentCode": "NA",
  "continent": "North America"
}
```

If you make a request to `/` (leaving off any IP address) Geode will
look up your IP address, checking for any `X-Forwarded-For` header, then
falling back to the socket address of your client.

[maxmind]: https://www.maxmind.com/
[geoip2-city]: https://www.maxmind.com/en/geoip2-city
[geolite2]: https://dev.maxmind.com/geoip/geoip2/geolite2/
