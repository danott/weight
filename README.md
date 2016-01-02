# Weight

Motivation: [I lost 60 pounds and realized two important things about eating with Google Docs](http://qz.com/437912/google-docs-helped-me-lose-60-pounds-and-realize-two-important-things-about-eating/)

This is a little Rake task to get weight data out of Fitbit, and into a Google
sheet for charting in the way described in the source article.

## Setup

1. Copy [this template Google sheet](https://docs.google.com/spreadsheets/d/13NUMpIpHKumFRGzayDIIfoXYVscvh1WsFG2Sf5fDkyo/edit?usp=sharing) with the name "Average Weight #{YEAR}"
2. Create an app at https://dev.fitbit.com, and save the client id and client secret into a file named `.env`
3. `bundle install`

## Usage

```
rake -T
```

