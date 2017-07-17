use Mix.Config

# layout configuration
config :stockboard, LayoutConfig,
  nav: %{left: [%{name: "logo", class: "logo", type: :span}],
         center: [%{name: "version", type: :txt},
                  %{name: "status", type: :txt}],
         right: [%{name: "home", type: :txt},
                 %{name: "notification", type: :txt},
                 %{name: "utils", type: :txt}]},
  sidebar: [%{name: "status",
              children: [%{name: "dashboard", link_to: "/"},
                         %{name: "stocks", link_to: "/stocks"},
                         %{name: "notifications", link_to: "/notifications"}]},
            %{name: "configuration",
              children: [%{name: "add stocks", link_to: "/stocks/new"}]},
            %{name: "system",
              children: [%{name: "utilities"}]}]
