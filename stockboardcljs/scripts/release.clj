(require '[cljs.build.api :as b])

(println "Building ...")

(let [start (System/nanoTime)]
  (b/build "src"
    {:output-to "priv/static/js/cljs-adv/stockboardcljs.js"
     :output-dir "priv/static/js/cljs-adv"
     :asset-path "/js/cljs"
     :optimizations :advanced
     :verbose true})
  (println "... done. Elapsed" (/ (- (System/nanoTime) start) 1e9) "seconds"))
