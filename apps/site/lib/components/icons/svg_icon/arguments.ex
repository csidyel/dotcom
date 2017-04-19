defmodule Site.Components.Icons.SvgIcon do
  defstruct [icon: :bus, class: "", show_tooltip?: true]

  @type t :: %__MODULE__{icon: icon_arg, class: String.t, show_tooltip?: boolean}
  @type icon_arg :: atom | String.t | Routes.Route.t | 0..4

  @icons [
    {:bus,
        "M15.0000409,19 L8.99995829,19 C8.99503143,19.5531447 8.55421988,20 8.00104344,20 L6.99895656,20 C6.45028851,20 6.00493267,19.5615199 6.00004069,18.9999777 C5.44710715,18.996349 5,18.5507824 5,17.9975592 L5,17.5024408 C5,16.948808 5,16.0551184 5,15.4982026 L5,5.00179743 C5,4.44851999 5.44994876,4 6.00684547,4 L17.9931545,4 C18.5492199,4 19,4.44488162 19,5.00179743 L19,15.4982026 C19,16.05148 19,16.9469499 19,17.5024408 L19,17.9975592 C19,18.5489355 18.5537115,18.9963398 17.9999585,18.9999777 C17.9950433,19.5531326 17.5542273,20 17.0010434,20 L15.9989566,20 C15.4502958,20 15.0049445,19.5615315 15.0000409,19 Z M13,8 L18,8 L18,14 L13,14 L13,8 Z M6,8 L11,8 L11,14 L6,14 L6,8 Z M8,5 L16,5 L16,7 L8,7 L8,5 Z M16,16 C16,15.4477153 16.4438648,15 17,15 C17.5522847,15 18,15.4438648 18,16 C18,16.5522847 17.5561352,17 17,17 C16.4477153,17 16,16.5561352 16,16 Z M13,16 C13,15.4477153 13.4438648,15 14,15 C14.5522847,15 15,15.4438648 15,16 C15,16.5522847 14.5561352,17 14,17 C13.4477153,17 13,16.5561352 13,16 Z M9,16 C9,15.4477153 9.44386482,15 10,15 C10.5522847,15 11,15.4438648 11,16 C11,16.5522847 10.5561352,17 10,17 C9.44771525,17 9,16.5561352 9,16 Z M6,16 C6,15.4477153 6.44386482,15 7,15 C7.55228475,15 8,15.4438648 8,16 C8,16.5522847 7.55613518,17 7,17 C6.44771525,17 6,16.5561352 6,16 Z"},

    {:commuter_rail,
        "M1,5.71428571 L0,6 L0,11.9970707 C0,12.5621186 0.450780073,13 1.00684547,13 L12.9931545,13 C13.5500512,13 14,12.5509732 14,11.9970707 L14,6 L13,5.71428571 L13,2.99980749 C13,2.44371665 12.5743491,1.85811638 12.0492822,1.68309405 L7.95071784,0.316905946 C7.4315052,0.143835068 6.57434913,0.141883625 6.04928216,0.316905946 L1.95071784,1.68309405 C1.4315052,1.85616493 1,2.44762906 1,2.99980749 L1,5.71428571 Z M12,11 C12.5522847,11 13,10.5522847 13,10 C13,9.44771525 12.5522847,9 12,9 C11.4477153,9 11,9.44771525 11,10 C11,10.5522847 11.4477153,11 12,11 Z M2,11 C2.55228475,11 3,10.5522847 3,10 C3,9.44771525 2.55228475,9 2,9 C1.44771525,9 1,9.44771525 1,10 C1,10.5522847 1.44771525,11 2,11 Z M2,3 L6,2 L6,4 L2,5 L2,3 Z M8,2 L12,3 L12,5 L8,4 L8,2 Z
        M1,14 L13,14 L13,14.5 C13,14.7761424 12.7709994,15 12.4996527,15 L1.50034732,15 C1.22401312,15 1,14.7680664 1,14.5 L1,14 Z M4,15 L6,15 L4,17 L2,17 L4,15 Z M8,15 L10,15 L12,17 L10,17 L8,15 Z"},

    {:subway,
        "M8,19 L9,19 L8,21 L7,21 L8,19 Z M15,19 L16,19 L17,21 L16,21 L15,19 Z M6,17.5024408 C6,16.948808 6,16.0488281 6,15.4932159 L6,7.00678414 C6,6.45075261 6.38567036,5.76271987 6.86301041,5.49531555 C6.86301041,5.49531555 9,4 12,4 C15,4 17.1369896,5.49531555 17.1369896,5.49531555 C17.6136171,5.77404508 18,6.45117188 18,7.00678414 L18,15.4932159 C18,16.0492474 18,16.9469499 18,17.5024408 L18,17.9975592 C18,18.551192 17.544239,19 16.9975267,19 L7.00247329,19 C6.44882258,19 6,18.5530501 6,17.9975592 L6,17.5024408 Z M9,7 C9,6.44771525 9.45097518,6 9.99077797,6 L14.009222,6 C14.5564136,6 15,6.44386482 15,7 C15,7.55228475 14.5490248,8 14.009222,8 L9.99077797,8 C9.44358641,8 9,7.55613518 9,7 Z M7.5,8 C7.77614237,8 8,7.77614237 8,7.5 C8,7.22385763 7.77614237,7 7.5,7 C7.22385763,7 7,7.22385763 7,7.5 C7,7.77614237 7.22385763,8 7.5,8 Z M16.5,8 C16.7761424,8 17,7.77614237 17,7.5 C17,7.22385763 16.7761424,7 16.5,7 C16.2238576,7 16,7.22385763 16,7.5 C16,7.77614237 16.2238576,8 16.5,8 Z M16,18 C16.5522847,18 17,17.5522847 17,17 C17,16.4477153 16.5522847,16 16,16 C15.4477153,16 15,16.4477153 15,17 C15,17.5522847 15.4477153,18 16,18 Z M8,18 C8.55228475,18 9,17.5522847 9,17 C9,16.4477153 8.55228475,16 8,16 C7.44771525,16 7,16.4477153 7,17 C7,17.5522847 7.44771525,18 8,18 Z M7,9.99077797 C7,9.44358641 7.4556644,9 7.99539757,9 L16.0046024,9 C16.5543453,9 17,9.45097518 17,9.99077797 L17,14.009222 C17,14.5564136 16.5443356,15 16.0046024,15 L7.99539757,15 C7.44565467,15 7,14.5490248 7,14.009222 L7,9.99077797 Z"},

    {:ferry,
        "M6,11 L4,12 C4,12 8.04431152,16 8,19 C8.51207606,19 9,18 10,18 C11,18 11,19 12,19 C13,19 13,18 14,18 C15,18 15.5915844,19 16,19 C16.0192871,16 20,12 20,12 L18,11 L18,7 L12,4 L6,7 L6,11 Z M7,8 L11,6 L11,8 L7,10 L7,8 Z M13,6 L17,8 L17,10 L13,8 L13,6 Z"},

    {:half_bus,
        "M0.5,0 l7,0 l0,2.58 l-6.75,0 a24,24 0 0 1 0.75,-2.58 m6.5,0 l0.5,0 l2,2.08 l0,0.5 l-2.5,0 m-7.3,0.5 l19,0
        l0,2 l-1,0 a10,10 0 0 1 1,3 l0.75,5 l0.5,0.1 l0.1,2 l-7,0 a3,3 0 0 0 0.1,-1 a1,1 0 0 0 -5,0 a3,3 0 0 0 0.1,1
        l-8,0 a24,24 0 0 1 -1,-5.1 l2,0 a1,1 0 0 0 1,-1 l0,-3 a1,1 0 0 0 -1,-1 l-1.95,0 a24,24 0 0 1 0.4,-2 m5,2 l6,0
        a1,1 0 0 1 1,1 l0,3 a1,1 0 0 1 -1,1 l-6,0 a1,1 0 0 1 -1,-1 l0,-3 a1,1 0 0 1 1,-1 m10,0 l1,0 a1,1 0 0 1 1,1 l0,3
        a1,1 0 0 1 -1,1 l-1,0 a1,1 0 0 1 -1,-1 l0,-3 a1,1 0 0 1 1,-1 m-4,7.15 a1,1 0 0 0 0,4 a1,1 0 0 0 0,-4 m0,1.5
        a0.5,0.5 0 0 1 0,1 a0.5,0.5 0 0 1 0,-1"},

    {:t_logo,
        "M0,0 l0,7 l9,0 l0,15.5 l7,0 l0,-15.5 l9,0 l0,-7 Z"},

    {:alert,
        "m10.981,1.436c0.818,-1.436 2.15,-1.425 2.962,0l10.166,17.865c0.818,1.437 0.142,2.602 -1.52,2.602l-20.259,0c-1.657,0 -2.33,-1.176 -1.52,-2.602l10.172,-17.865l-0.001,0zm-0.359,6.92l3,0l0,6l-3,0l0,-6zm0,7.53l3,0l0,3l-3,0l0,-3z"},

    {:access,
        "M17 22.4c-1.5 3-4.6 5-8 5-5 0-9-4-9-9 0-3.5 2-6.7 5.3-8.2l.2 2.7c-2 1-3 3.2-3 5.4C2.5 22 5.5 25 9 25
        c3.3 0 6-2.6 6.5-5.8l1.6 3.2zM8 5c1.3-.2 2.2-1.3 2.2-2.6S9.2 0 7.8 0C6.5 0 5.4 1 5.4 2.4c0 .5 0 1 .3 1.2L6.5 16
        h9l3.7 8.5 4.8-2-.7-1.7-2.7 1-3.6-8.2H8.7V12h6V10H8.2l-.3-5z"},


    {:map,
        "M1,4 l8,-3 l8,3 l8,-3 l0,20 l-8,3 l-8,-3 l-8,3 Z M9,2 l0,19 M17,4 l0,19"},

    {:globe,
        "M5,5 a10,10 0 0 1 20,20 a10,10 0 0 1 -20,-20 m-1,1 l22,0 m3,8 l-28,0 m2,8 l24.5,0 m-12.5,7 l0,-28 m0,0
        a12,15 0 0 0 0,28 a12,15 0 0 0 0,-28"},

    {:phone,
        "M1 .4c-1.8 8 4.2 21 14.7 22l1.7-5s0-.4-.3-.6l-4.4-2.6-2.7 1.3c-1.5-1.2-4.4-4.6-5-7 1-.8 2.3-2.2 2.3-2.2
        s-.8-5-1-5.4c0-.5-.2-.6-.6-.6H1z"},

    {:suitcase,
        "M7.0893.1035c-.2945.0277-.519.2756-.518.5714v2.857H0v5.4286h10.2857V7.532h3.4286v1.4286H24V3.532h-6.5714V.675
        c0-.3157-.256-.5715-.5715-.5715H7.143c-.018-.001-.036-.001-.0537 0zm.625 1.1428h8.5714V3.532H7.7143V1.2464z
        M0 10.1035v8.857h24v-8.857H13.7143v1.4286h-3.4286v-1.4285H0z"},

    {:tools,
        "M12.54 9.3c.25-.26.45-.3.76.02l.25.23
        c.12-.1.2-.17.28-.26 1.72-1.72 3.4-3.44 5.1-5.16.23-.22.42-.5.57-.8 1.12-2.02.67-1.54 2.56-2.66l.62-.34
        c.08-.03.17-.1.25-.1.45-.04.5.1.76.4.2.26.16.52 0 .8-.37.6-.68 1.18-1.05
        1.77-.14.24-.34.43-.54.55-.5.3-1.06.6-1.6.9-.16.08-.3.2-.44.3-1.8 1.73-3.55 3.5-5.3 5.25-.2.2-.22.33 0
        .53.26.25.26.5 0 .76l-2.22-2.2zm-1.04 5.88
        c-.57.28-1.47 1.04-1.97 1.46-.88.77-1.64 1.67-2.1 2.74-.16.36-.2.78-.33 1.2-.05.15-.1.32-.2.4-.75.8-1.54
        1.58-2.33 2.37-.73.7-1.86.7-2.6 0-.47-.45-.78-.73-1.23-1.2-.7-.72-.73-1.82-.06-2.55.8-.84 1.64-1.66
        2.45-2.48.06-.05.17-.1.26-.14 1.1-.14 2.07-.67 2.92-1.4.9-.77 2.05-2 2.53-3.08l2.65 2.68z m10.56 8.8c-.48
        0-.85-.27-1.18-.58
        l-6.45-6.47c-2.06-2.06-4.1-4.1-6.14-6.1-1.08-1.1-2.35-1.93-3.76-2.5-.42-.16-.82-.02-1.2.12-.12.03-.3.06-.38 0
        C1.44 7.45.46 6.08 0 4.3c-.02-.1.04-.33.12-.38.08-.06.28 0 .4.05 1.15.68 2.3 1.35 3.5 2
        .5.28.5.28.8-.22.34-.6.68-1.16 1-1.75.2-.37.13-.56-.24-.8-1.15-.66-2.3-1.34-3.46-2.04-.1-.06-.28-.26-.25-.3.05-.16.2-.3.3-.32
        C3.4.14 4.66-.08 5.96.04c2.2.2 3.77 2.16 3.52 4.35-.2 1.63.3 2.95 1.46 4.08L23.43 21 c.57.57.7
        1.28.4 1.95-.34.68-1 1.1-1.77 1.04zm.84-1.06c.3-.3.28-.92-.03-1.26-.33-.37-.98-.4-1.3-.1-.33.35-.3.9
        7.04 1.3.35.37 1 .4 1.3.06z"},
    {:the_ride,
     "M9.987 7v1.547H6.942v8.575H5.06V8.547H2V7h7.987zm9.737
     10.122h-1.897v-4.424H13.08v4.424h-1.896V7h1.897v4.354h4.747V7h1.897v10.122zM28.152
     7v1.498h-4.487v2.807H27.2v1.45h-3.535v2.862h4.487v1.505h-6.384V7h6.384zM4.8 25.167v3.955H2.917V19h3.087c.69
     0 1.282.07 1.775.213.49.143.894.342 1.21.6.315.256.545.562.692.92.148.357.22.75.22 1.18 0
     .34-.05.662-.15.965-.1.303-.244.58-.434.826-.19.247-.422.464-.7.65-.277.188-.593.337-.948.45.238.134.443.328.616.58l2.534
     3.738H9.126c-.163
     0-.302-.033-.416-.098-.115-.065-.212-.16-.29-.28l-2.13-3.24c-.078-.122-.166-.21-.26-.26-.097-.05-.238-.077-.425-.077H4.8zm0-1.35h1.176c.355
     0 .664-.045.928-.134.263-.09.48-.21.65-.367.17-.157.298-.342.382-.557.084-.216.126-.45.126-.708
     0-.513-.17-.908-.507-1.183-.34-.276-.856-.414-1.55-.414H4.8v3.36zm9.345
     5.305h-1.89V19h1.89v10.122zm11.263-5.06c0 .74-.124 1.422-.37 2.043-.248.62-.596 1.155-1.044
     1.603-.448.448-.987.796-1.617 1.043-.63.248-1.328.372-2.093.372H16.42V19h3.864c.765 0 1.463.125
     2.093.375.63.25 1.17.597 1.617 1.043.448.445.796.978 1.043 1.6.247.62.37 1.3.37 2.043zm-1.925
     0c0-.556-.075-1.054-.224-1.495-.15-.442-.363-.815-.638-1.12-.275-.306-.61-.54-1.005-.704-.394-.163-.838-.245-1.333-.245h-1.967v7.126h1.967c.495
     0 .94-.082 1.334-.245.394-.164.73-.4 1.004-.704.275-.306.488-.68.637-1.12.148-.442.223-.94.223-1.495zM33.27
     19v1.498H28.78v2.807h3.535v1.45h-3.535v2.862h4.487v1.505h-6.385V19h6.384z"
    },
    {:twitter,
     "M153.62,301.59c94.34,0,145.94-78.16,145.94-145.94,0-2.22,0-4.43-.15-6.63A104.36,104.36,0,0,0,325,122.47a102.38,102.38,0,0,1-29.46,8.07,51.47,51.47,0,0,0,22.55-28.37,102.79,102.79,0,0,1-32.57,12.45,51.34,51.34,0,0,0-87.41,46.78A145.62,145.62,0,0,1,92.4,107.81a51.33,51.33,0,0,0,15.88,68.47A50.91,50.91,0,0,1,85,169.86c0,.21,0,.43,0,.65a51.31,51.31,0,0,0,41.15,50.28,51.21,51.21,0,0,1-23.16.88,51.35,51.35,0,0,0,47.92,35.62,102.92,102.92,0,0,1-63.7,22A104.41,104.41,0,0,1,75,278.55a145.21,145.21,0,0,0,78.62,23"
    },
    {:facebook,
     "M40.43,21.739h-7.645v-5.014c0-1.883,1.248-2.322,2.127-2.322c0.877,0,5.395,0,5.395,0V6.125l-7.43-0.029  c-8.248,0-10.125,6.174-10.125,10.125v5.518h-4.77v8.53h4.77c0,10.947,0,24.137,0,24.137h10.033c0,0,0-13.32,0-24.137h6.77  L40.43,21.739z"
    },
    {:nineoneone,
    "M45.638 100C41.56 88.692 29.16 86.465 19.293 84.146c-8.095-1.902-14.417-6.61-17.25-13.75-7.117-15.685 6.495-27.43 8.383-41.732.944-7.046-3.155-12.574-7-17.94l6.54-7.464C20.836 8.81 36.08 7.394 45.638 0c9.56 7.394 24.802 8.82 35.672 3.27l6.542 7.46c-3.848 5.367-7.946 10.895-7 17.943 1.888 14.303 15.5 26.048 8.382 41.732-2.832 7.14-9.154 11.846-17.25 13.75-9.87 2.32-22.27 4.537-26.346 15.845z"
    }
  ] |> Map.new

  def variants() do
    # remove the default icon
    other_icons = Map.drop(@icons, [%__MODULE__{}.icon])
    for {icon, _path} <- other_icons do
      {icon_title(icon),
       %__MODULE__{
         icon: icon
       }}
    end
  end

  def get_path(atom) when atom in [:green_line, :red_line, :blue_line, :orange_line, :mattapan_line], do: get_path(:t_logo)
  def get_path(atom) when is_atom(atom) do
    @icons
    |> Map.get(atom)
    |> String.replace(~r/\n/, "")
    |> String.replace(~r/\t/, "")
    |> String.replace(~r/\s\s/, " ")
    |> build_path
  end
  def get_path(arg), do: get_path(get_icon_atom(arg))

  @spec get_icon_atom(icon_arg) :: atom
  def get_icon_atom(arg) when is_atom(arg), do: arg
  def get_icon_atom("Elevator"), do: :access
  def get_icon_atom("Escalator"), do: :access
  def get_icon_atom(route_type) when route_type in [0,1,2,3,4], do: Routes.Route.type_atom(route_type)
  def get_icon_atom(%Routes.Route{} = route), do: Routes.Route.icon_atom(route)
  def get_icon_atom(arg) when is_binary(arg) do
    arg
    |> String.downcase
    |> String.replace(" ", "_")
    |> String.to_atom
  end

  @spec icon_title(atom) :: String.t
  def icon_title(:alert), do: "Service alert or delay"
  def icon_title(icon), do: "#{icon} icon"

  def build_path(path), do: Phoenix.HTML.Tag.tag :path, d: path

  def viewbox(:bus), do: "24 24"
  def viewbox(:subway), do: "24 24"
  def viewbox(:commuter_rail), do: "16 16"
  def viewbox(:map), do: "26 24"
  def viewbox(:alert), do: "24 24"
  def viewbox(:the_ride), do: "36 36"
  def viewbox(:twitter), do: "400 400"
  def viewbox(:facebook), do: "75 75"
  def viewbox(_), do: "40 40"

  def unoptimized_paths, do: @icons
end
