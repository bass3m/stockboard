(require '[cljs.build.api :as b])

(b/watch "src"
  {:main 'stockboardcljs.core
   :output-to "priv/static/js/cljs/stockboardcljs.js"
   :output-dir "priv/static/js/cljs"
   :asset-path "/js/cljs"})
