(require '[cljs.build.api :as b])

(println "Building ...")

(let [start (System/nanoTime)]
  (b/build "src"
    {:main 'stockboardcljs.core
     :output-to "../priv/static/js/cljs/stockboardcljs.js"
     :output-dir "../priv/static/js/cljs"
     :asset-path "/js/cljs"
     :verbose true})
  (println "... done. Elapsed" (/ (- (System/nanoTime) start) 1e9) "seconds"))


