**[What is it ?](#what-is-it)** |
**[Quickstart](#quickstart)** |
**[Configuration](#configuration)**

## What is it ?
Stockboard is a application created with the intention of playing around with [Phoenix](http://www.phoenixframework.org/).
In addition, some of my other goals for this application was to use the [Bulma CSS Framework](http://bulma.io/) 
and [Chart.js](http://www.chartjs.org/). For the frontend piece, I wanted to use [clojurescript](https://clojurescript.org/).
Obligatory screenshot:

![Stockboard screenshot](https://github.com/bass3m/stockboard/blob/master/images/preview.png) 

## Quickstart
```
# fetch and compile dependencies
$ mix deps.get
$ mix compile

# compile clojurescript. might need to download [leiningen](https://leiningen.org/)
$ cd stockboardcljs
$ lein deps
$ ./scripts/build

# build assets
$ brunch build

# Db tasks
$ mix ecto.create
$ mix ecto.migrate
# start server
$ mix phoenix.server
```

Then point your browser to http://localhost:4000

## Configuration

![Stock quote configuration screenshot](https://github.com/bass3m/stockboard/blob/master/images/stock_cfg.png) 
You can add stocks to track using the `add stocks` tab.
Here's a description of what some of these stock configuration options mean:
  * Symbol : stock ticker symbol. GOOGL for example.
  * Exchange : the stock exchange where the stock is traded. Currently only NYSE or NASDAQ.
  * Name : A name to associate with the stock symbol.
  * Update every : Interval in seconds for refreshing the stock quote.
  * Save every : Interval in minutes for saving stock quotes into the Database. The application currently persists : the price (current/high/low) as well as the volume.
  * Keep for : How many days to keep the quotes in the Database.
