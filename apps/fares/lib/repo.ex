defmodule Fares.Repo.ZoneFares do
  alias Fares.Fare

  @spec fare_info() :: [Fare.t]
  def fare_info do
    filename = "priv/fares.csv"

    filename
    |> File.stream!
    |> CSV.decode
    |> Enum.flat_map(&mapper/1)
  end

  @lint {Credo.Check.Refactor.ABCSize, false}
  @spec mapper([String.t]) :: [Fare.t]
  def mapper(["commuter", zone, single_trip, single_trip_reduced, monthly | _]) do
    base = %Fare{
      mode: :commuter,
      name: commuter_rail_fare_name(zone)
    }
    [
      %Fare{base |
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(single_trip),},
      %Fare{base |
        duration: :single_trip,
        pass_type: :student_card,
        reduced: :student,
        cents: dollars_to_cents(single_trip_reduced)},
      %Fare{base |
        duration: :single_trip,
        pass_type: :ticket,
        reduced: :senior_disabled,
        cents: dollars_to_cents(single_trip_reduced)},
      %Fare{base |
        duration: :round_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(single_trip) * 2},
      %Fare{base |
        duration: :round_trip,
        pass_type: :student_card,
        reduced: :student,
        cents: dollars_to_cents(single_trip_reduced) * 2},
      %Fare{base |
        duration: :round_trip,
        pass_type: :senior_card,
        reduced: :senior_disabled,
        cents: dollars_to_cents(single_trip_reduced) * 2},
      %Fare{base |
        duration: :month,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(monthly),
        additional_valid_modes: [:subway, :bus, :ferry]
      },
      %Fare{base |
        duration: :month,
        pass_type: :mticket,
        reduced: nil,
        cents: dollars_to_cents(monthly) - 1000}
    ]
  end
  def mapper([
    "subway",
    charlie_card_price,
    ticket_price,
    day_reduced_price,
    month_reduced_price,
    day_pass_price,
    week_pass_price,
    month_pass_price,
    ""
  ]) do
    base = %Fare{
      mode: :subway,
      name: :subway
    }
    [
      %Fare{base |
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: nil,
        cents: dollars_to_cents(charlie_card_price),
        additional_valid_modes: [:bus]
      },
      %Fare{base |
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(ticket_price),
        additional_valid_modes: [:bus]
      },
      %Fare{base |
        duration: :single_trip,
        pass_type: :student_card,
        reduced: :student,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{base |
        duration: :single_trip,
        pass_type: :senior_card,
        reduced: :senior_disabled,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{base |
        duration: :month,
        pass_type: :student_card,
        reduced: :student,
        cents: dollars_to_cents(month_reduced_price),
        additional_valid_modes: [:bus]
      },
      %Fare{base |
        duration: :month,
        pass_type: :senior_card,
        reduced: :senior_disabled,
        cents: dollars_to_cents(month_reduced_price),
        additional_valid_modes: [:bus]
      },
      %Fare{base |
        duration: :day,
        pass_type: :card_or_ticket,
        reduced: nil,
        cents: dollars_to_cents(day_pass_price),
        additional_valid_modes: [:bus]
      },
      %Fare{base |
        duration: :week,
        pass_type: :card_or_ticket,
        reduced: nil,
        cents: dollars_to_cents(week_pass_price),
        additional_valid_modes: [:bus]
      },
      %Fare{base |
        duration: :month,
        pass_type: :card_or_ticket,
        reduced: nil,
        cents: dollars_to_cents(month_pass_price),
        additional_valid_modes: [:bus]
      }
    ]
  end
  def mapper([
    "local_bus",
    charlie_card_price,
    ticket_price,
    day_reduced_price,
    month_reduced_price,
    _day_pass_price,
    _week_pass_price,
    _month_pass_price,
    ""
  ]) do
    base = %Fare{
      mode: :bus,
      name: :local_bus
    }
    [
      %Fare{base |
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: nil,
        cents: dollars_to_cents(charlie_card_price)
      },
      %Fare{base |
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(ticket_price)
      },
      %Fare{base |
        duration: :single_trip,
        pass_type: :student_card,
        reduced: :student,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{base |
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: :senior_disabled,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{base |
        duration: :month,
        pass_type: :student_card,
        reduced: :student,
        cents: dollars_to_cents(month_reduced_price)
      }
    ]
  end
  def mapper([
    mode,
    charlie_card_price,
    ticket_price,
    day_reduced_price,
    month_reduced_price,
    _day_pass_price,
    week_pass_price,
    month_pass_price,
    ""
  ])
  when mode in ["local_bus", "inner_express_bus", "outer_express_bus"] do
    base = %Fare{
      mode: :bus,
      name: :"#{mode}"
    }
    [
      %Fare{base |
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: nil,
        cents: dollars_to_cents(charlie_card_price)
      },
      %Fare{base |
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(ticket_price)
      },
      # %Fare{base |
      #   duration: :single_trip,
      #   pass_type: :student_card,
      #   reduced: :student,
      #   cents: dollars_to_cents(day_reduced_price)
      # },
      %Fare{base |
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: :senior_disabled,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{base |
        duration: :month,
        pass_type: :student_card,
        reduced: :student,
        cents: dollars_to_cents(month_reduced_price)
      },
      %Fare{base |
        duration: :month,
        pass_type: :charlie_card,
        reduced: :senior_disabled,
        cents: dollars_to_cents(month_reduced_price)
      },
      # %Fare{base |
      #   duration: :day,
      #   pass_type: :card_or_ticket,
      #   reduced: nil,
      #   cents: dollars_to_cents(day_pass_price),
      #   additional_valid_modes: [:bus]
      # },
      %Fare{base |
        duration: :week,
        pass_type: :card_or_ticket,
        reduced: nil,
        cents: dollars_to_cents(week_pass_price),
        additional_valid_modes: [:bus]
      },
      %Fare{base |
        duration: :month,
        pass_type: :card_or_ticket,
        reduced: nil,
        cents: dollars_to_cents(month_pass_price),
        additional_valid_modes: [:bus]
      }
    ]
  end
  def mapper([
    "ferry",
    inner_harbor_price,
    inner_harbor_month_price,
    cross_harbor_price,
    commuter_ferry_price,
    commuter_ferry_month_price,
    commuter_ferry_logan_price,
    day_pass_price,
    week_pass_price
  ]) do
    fares = [
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(inner_harbor_price)
      },
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :round_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(inner_harbor_price) * 2
      },
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :month,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(inner_harbor_month_price),
        additional_valid_modes: [:subway, :bus, :commuter]
      },
      %Fare{
        mode: :ferry,
        name: :ferry_cross_harbor,
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(cross_harbor_price)
      },
      %Fare{
        mode: :ferry,
        name: :ferry_cross_harbor,
        duration: :round_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(cross_harbor_price) * 2
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_price)
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :round_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_price) * 2
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry_logan,
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_logan_price)
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry_logan,
        duration: :round_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_logan_price) * 2,
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :month,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_month_price),
        additional_valid_modes: [:subway, :bus, :commuter]
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :month,
        pass_type: :mticket,
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_month_price) - 1000
      },
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :day,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(day_pass_price)
      },
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :week,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(week_pass_price)
      }
    ]

    reduced_fares = fares
    |> Enum.filter(&(&1.duration in [:single_trip, :round_trip]))
    |> Enum.flat_map(fn fare ->
      reduced_price = round(fare.cents / 2)
      [
        %Fare{fare | cents: reduced_price, pass_type: :senior_card, reduced: :senior_disabled},
        %Fare{fare | cents: reduced_price, pass_type: :student_card, reduced: :student}
      ]
    end)
    fares ++ reduced_fares
  end

  defp commuter_rail_fare_name(zone) do
    case String.split(zone, "_") do
      ["zone", zone] -> {:zone, String.upcase(zone)}
      ["interzone", zone] -> {:interzone, String.upcase(zone)}
    end
  end

  defp dollars_to_cents(dollars) do
    dollars
    |> String.to_float
    |> Kernel.*(100)
    |> round
  end
end

defmodule Fares.Repo do
  import Fares.Repo.ZoneFares
  @fares fare_info

  alias Fares.Fare

  @spec all() :: [Fare.t]
  @spec all(Keyword.t) :: [Fare.t]
  def all() do
    @fares
  end
  def all(opts) when is_list(opts) do
    all
    |> filter(opts)
  end

  @spec filter([Fare.t], Dict.t) :: [Fare.t]
  def filter(fares, opts) do
    fares
    |> filter_all(Map.new(opts))
  end

  @spec filter_all([Fare.t], %{}) :: [Fare.t]
  defp filter_all(fares, opts) do
    Enum.filter(fares, fn fare -> match?(^opts, Map.take(fare, Map.keys(opts))) end)
  end
end
