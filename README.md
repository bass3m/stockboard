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
```

Then point your browser to http://localhost:4000

## Configuration
