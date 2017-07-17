(defproject stockboardcljs "0.1.0-SNAPSHOT"
  :description "cljs for phoenix"
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [org.clojure/clojurescript "1.9.671"]
                 [org.clojure/core.async "0.3.443"]
                 [cljsjs/moment "2.17.1-1"]]
  :jvm-opts ^:replace ["-Xmx1g" "-server"]
  :plugins [[lein-npm "0.6.2"]]
  :npm {:dependencies [[source-map-support "0.4.0"]]}
  :source-paths ["src" "target/classes"]
  :clean-targets ["../priv/static/js/cljs" "../priv/static/js/cljs-adv"]
  :target-path "target")
