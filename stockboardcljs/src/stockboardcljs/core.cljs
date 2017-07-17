(ns stockboardcljs.core
  (:require [cljs.core.async :as async :refer [<! >! chan close! put! alts!]]
            [cljsjs.moment :as moment]
            [cljs.pprint :refer [pprint]]
            [clojure.browser.repl :as repl])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defonce app-state (atom {}))

(defn get-state [k & [default]]
  (clojure.core/get @app-state k default))

(defn put-state! [k v]
  (swap! app-state assoc k v))

;; (defonce conn
;;   (repl/connect "http://localhost:9000/repl"))

(enable-console-print!)

(defn log
  [& args]
  (.apply js/console.log js/console (into-array args)))

(defn by-id
  "Short-hand for document.getElementById(id)"
  [id]
  (.getElementById js/document id))

(defn by-class
  "Short-hand for document.getElementByClassName(class)"
  [class]
  (aget (.getElementsByClassName js/document class) 0))

(defn handle-in-msg
  [in-chan payload]
  ;;(println "payload:" payload (js->clj payload))
  (put! in-chan payload))

(defn channel-setup
  [socket in-chan]
  (let [channel (.channel socket "metrics:stockboard" #js{})]
    (.on channel "new_msg" (fn [payload] (handle-in-msg in-chan payload)))
    (.. channel
        (join)
        (receive "ok" (fn [resp] (println "Joined successfully" resp)))
        (receive "error" (fn [resp] (println "Unable to join" resp))))
    channel))

(defn update-data!
  [arr new-entry history]
  ;;(println "update-data:" arr new-entry history)
  (.push arr new-entry)
  (when (> (count arr) history)
    (.shift arr)))

(defn update-chart-data
  [chart new-label new-dataset labels]
  (let [current-dataset (.-datasets (.-data chart))
        current-labels (.-labels (.-data chart))]
    (doall
     (map (fn [ds new-ds label]
            (doall
             (update-data! (.-data ds) new-ds 100)
             (set! (.-label ds) label)))
          current-dataset new-dataset labels))
    (update-data! current-labels new-label 100))
  (.update chart))

(defmulti handle-server-msg :metric)

(defmethod handle-server-msg "realtime_sector_data"
  [msg]
  (let [title (-> msg :body :title)
        dataset (-> msg :body :dataset)
        labels (-> msg :body :labels)
        new-date (.toDate (js/moment))
        sector-chart (get-state "sectors")
        chart (:chart sector-chart)]
    (update-chart-data chart new-date dataset labels)))

(defmethod handle-server-msg "realtime_stock_data"
  [msg]
  (let [symbol (-> msg :body :symbol)
        exchange (-> msg :body :exchange)
        price (-> msg :body :price)
        price-low (-> msg :body :price_low)
        price-hi (-> msg :body :price_hi)
        volume (-> msg :body :volume)
        now (.toDate (js/moment))
        price-div-id (str symbol ":" exchange ":price")
        volume-div-id (str symbol ":" exchange ":volume")
        price-hi-div-id (str symbol ":" exchange ":price_hi")
        price-low-div-id (str symbol ":" exchange ":price_low")]
    (doall
     (map
      (fn [div-id txt] (set! (.-textContent (by-id div-id)) txt))
      [price-div-id volume-div-id price-hi-div-id price-low-div-id]
      [price volume price-hi price-low]))))

(defmethod handle-server-msg :default
  [msg]
  (println "Don't know what to do with msg:" msg))

(defn handle-server-msg*
  [msg]
  (let [msg (-> msg (js->clj :keywordize-keys true))]
    ;;(println "handle-server-msg* msg:" msg)
    (handle-server-msg msg)))

(defn chart-cfg
  []
  (let [colors ["#1fc8db" "#fce473","#42afe3" "#ed6c63" "#97cd76"]]
    {:type "line",
     :data {:labels []
            :datasets (mapv (fn [c]
                              {:label ""
                               :data []
                               ;;:data {:labels [] :datasets []}
                               :fill false
                               :backgroundColor c
                               :borderColor c
                               :pointBackgroundColor c
                               :pointBorderColor c})
                            colors)}
     :options {:animation false
               :title {:text "My title"} ;; XXX passed with data
               :scales {:xAxes [{:type "time"
                                 :time {:format "HH:mm:ss.SSS"
                                        :tooltipFormat "ll HH:mm:ss.SSS"}
                                 :scaleLabel {:display false
                                              :labelString "Date"}}]
                        :yAxes [{:scaleLabel {:display false
                                              :labelString "value"}}]}}}))

(defn get-dom-charts []
  (array-seq (.getElementsByClassName js/document "chart")))

(defn init-chart!
  [chart-el cfg]
  (let [chart (js/Chart. chart-el (clj->js cfg))
        chart-id (.-id chart-el)]
;;    (println "init chart: el:" chart-el ":id:" chart-id "chart" chart)
    (put-state! chart-id {:chart chart})))

;; XXX grab all charts from templates ?
(defn init! []
  (let [charts-seq (get-dom-charts)]
    (doall
     (map (fn [chart] (init-chart! chart (chart-cfg))) charts-seq))))

(defn run
  [socket]
  (println "running cljs/phoenix!")
  (init!)
  (.connect socket)
  (.onOpen socket (fn [] (println "connected!")))
  (go
    (let [in-chan (chan)
          out-chan (chan)
          wschannel (channel-setup socket in-chan)]
      (loop []
        (let [[m c] (alts! [in-chan out-chan])]
          (condp = c
            in-chan (handle-server-msg* m)
            out-chan (println "send to server" m))
          (recur))))))
