defmodule Fares.FareInfo do
  alias Fares.Fare

  @filename "priv/fares.csv"

  @spec grouped_fares(Path.t()) :: [Fares.CommuterFareGroup.t()]
  def grouped_fares(filename \\ @filename) do
    :fares
    |> Application.app_dir()
    |> Path.join(filename)
    |> File.stream!()
    |> CSV.decode()
    |> Enum.flat_map(&zone_mapper/1)
  end

  @spec zone_mapper([String.t()]) :: [Fares.CommuterFareGroup.t()]
  def zone_mapper(["commuter", zone, single_trip, single_trip_reduced, monthly | _]) do
    [
      %Fares.CommuterFareGroup{
        name: commuter_rail_fare_name(zone),
        single_trip: dollars_to_cents(single_trip),
        single_trip_reduced: dollars_to_cents(single_trip_reduced),
        month: dollars_to_cents(monthly),
        mticket: mticket_price(dollars_to_cents(monthly))
      }
    ]
  end

  def zone_mapper(_) do
    []
  end

  @doc "Load fare info from a CSV file."
  @spec fare_info() :: [Fare.t()]
  @spec fare_info(Path.t()) :: [Fare.t()]
  def fare_info(filename \\ @filename) do
    :fares
    |> Application.app_dir()
    |> Path.join(filename)
    |> File.stream!()
    |> CSV.decode()
    |> Enum.flat_map(&mapper/1)
    |> Enum.concat(free_fare())
  end

  @doc "Special fare used only for inbound trips from the airport"
  @spec free_fare() :: [Fare.t()]
  def free_fare do
    [
      %Fare{
        mode: :bus,
        name: :free_fare,
        duration: :single_trip,
        media: [],
        reduced: nil,
        cents: dollars_to_cents("0.00")
      }
    ]
  end

  _ = @lint {Credo.Check.Refactor.ABCSize, false}
  @spec mapper([String.t()]) :: [Fare.t()]
  def mapper(["commuter", zone, single_trip, single_trip_reduced, monthly | _]) do
    base = %Fare{
      mode: :commuter_rail,
      name: commuter_rail_fare_name(zone)
    }

    [
      %{
        base
        | duration: :single_trip,
          media: [:commuter_ticket, :cash, :mticket],
          reduced: nil,
          cents: dollars_to_cents(single_trip)
      },
      %{
        base
        | duration: :single_trip,
          media: [:student_card],
          reduced: :student,
          cents: dollars_to_cents(single_trip_reduced)
      },
      %{
        base
        | duration: :single_trip,
          media: [:senior_card],
          reduced: :senior_disabled,
          cents: dollars_to_cents(single_trip_reduced)
      },
      %{
        base
        | duration: :round_trip,
          media: [:commuter_ticket, :cash, :mticket],
          reduced: nil,
          cents: dollars_to_cents(single_trip) * 2
      },
      %{
        base
        | duration: :round_trip,
          media: [:student_card],
          reduced: :student,
          cents: dollars_to_cents(single_trip_reduced) * 2
      },
      %{
        base
        | duration: :round_trip,
          media: [:senior_card],
          reduced: :senior_disabled,
          cents: dollars_to_cents(single_trip_reduced) * 2
      },
      %{
        base
        | duration: :month,
          media: [:commuter_ticket],
          reduced: nil,
          cents: dollars_to_cents(monthly),
          additional_valid_modes: monthly_commuter_modes(zone)
      },
      %{
        base
        | duration: :month,
          media: [:mticket],
          reduced: nil,
          cents: mticket_price(dollars_to_cents(monthly))
      }
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
      %{
        base
        | duration: :month,
          media: [:charlie_card, :charlie_ticket],
          reduced: nil,
          cents: dollars_to_cents(month_pass_price),
          additional_valid_modes: [:bus]
      },
      %{
        base
        | duration: :month,
          media: [:student_card],
          reduced: :student,
          cents: dollars_to_cents(month_reduced_price),
          additional_valid_modes: [:bus]
      },
      %{
        base
        | duration: :month,
          media: [:senior_card],
          reduced: :senior_disabled,
          cents: dollars_to_cents(month_reduced_price),
          additional_valid_modes: [:bus]
      },
      %{
        base
        | duration: :single_trip,
          media: [:charlie_card],
          reduced: nil,
          cents: dollars_to_cents(charlie_card_price),
          additional_valid_modes: [:bus]
      },
      %{
        base
        | duration: :single_trip,
          media: [:charlie_ticket, :cash],
          reduced: nil,
          cents: dollars_to_cents(ticket_price),
          additional_valid_modes: [:bus]
      },
      %{
        base
        | duration: :single_trip,
          media: [:student_card],
          reduced: :student,
          cents: dollars_to_cents(day_reduced_price)
      },
      %{
        base
        | duration: :single_trip,
          media: [:senior_card],
          reduced: :senior_disabled,
          cents: dollars_to_cents(day_reduced_price)
      },
      %{
        base
        | duration: :week,
          media: [:charlie_card, :charlie_ticket],
          reduced: nil,
          cents: dollars_to_cents(week_pass_price),
          additional_valid_modes: [:bus, :commuter_rail, :ferry]
      },
      %{
        base
        | duration: :day,
          media: [:charlie_card, :charlie_ticket],
          reduced: nil,
          cents: dollars_to_cents(day_pass_price),
          additional_valid_modes: [:bus, :commuter_rail, :ferry]
      }
    ]
  end

  def mapper([
        "local_bus",
        charlie_card_price,
        ticket_price,
        day_reduced_price,
        _month_reduced_price,
        _day_pass_price,
        _week_pass_price,
        month_pass_price,
        ""
      ]) do
    base = %Fare{
      mode: :bus,
      name: :local_bus
    }

    [
      %{
        base
        | duration: :single_trip,
          media: [:charlie_card],
          reduced: nil,
          cents: dollars_to_cents(charlie_card_price)
      },
      %{
        base
        | duration: :single_trip,
          media: [:charlie_ticket, :cash],
          reduced: nil,
          cents: dollars_to_cents(ticket_price)
      },
      %{
        base
        | duration: :single_trip,
          media: [:student_card],
          reduced: :student,
          cents: dollars_to_cents(day_reduced_price)
      },
      %{
        base
        | duration: :single_trip,
          media: [:senior_card],
          reduced: :senior_disabled,
          cents: dollars_to_cents(day_reduced_price)
      },
      %{
        base
        | duration: :month,
          media: [:charlie_card, :charlie_ticket],
          reduced: nil,
          cents: dollars_to_cents(month_pass_price)
      }
    ]
  end

  def mapper([
        mode,
        charlie_card_price,
        ticket_price,
        day_reduced_price,
        _month_reduced_price,
        _day_pass_price,
        _week_pass_price,
        month_pass_price,
        ""
      ])
      when mode in ["inner_express_bus", "outer_express_bus"] do
    base = %Fare{
      mode: :bus,
      name: :"#{mode}"
    }

    [
      %{
        base
        | duration: :single_trip,
          media: [:charlie_card],
          reduced: nil,
          cents: dollars_to_cents(charlie_card_price)
      },
      %{
        base
        | duration: :single_trip,
          media: [:charlie_ticket, :cash],
          reduced: nil,
          cents: dollars_to_cents(ticket_price)
      },
      %{
        base
        | duration: :single_trip,
          media: [:student_card],
          reduced: :student,
          cents: dollars_to_cents(day_reduced_price)
      },
      %{
        base
        | duration: :single_trip,
          media: [:senior_card],
          reduced: :senior_disabled,
          cents: dollars_to_cents(day_reduced_price)
      },
      %{
        base
        | duration: :month,
          media: [:charlie_card, :charlie_ticket],
          reduced: nil,
          cents: dollars_to_cents(month_pass_price)
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
        _day_pass_price,
        _week_pass_price
      ]) do
    fares = [
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :single_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(inner_harbor_price)
      },
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :round_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(inner_harbor_price) * 2
      },
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :month,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(inner_harbor_month_price),
        additional_valid_modes: [:subway, :bus, :commuter_rail]
      },
      %Fare{
        mode: :ferry,
        name: :ferry_inner_harbor,
        duration: :month,
        media: [:mticket],
        reduced: nil,
        cents: dollars_to_cents(inner_harbor_month_price) - 1000
      },
      %Fare{
        mode: :ferry,
        name: :ferry_cross_harbor,
        duration: :single_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(cross_harbor_price)
      },
      %Fare{
        mode: :ferry,
        name: :ferry_cross_harbor,
        duration: :round_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(cross_harbor_price) * 2
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :single_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_price)
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :round_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_price) * 2
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry_logan,
        duration: :single_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_logan_price)
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry_logan,
        duration: :round_trip,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_logan_price) * 2
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :month,
        media: [:charlie_ticket],
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_month_price),
        additional_valid_modes: [:subway, :bus, :commuter_rail]
      },
      %Fare{
        mode: :ferry,
        name: :commuter_ferry,
        duration: :month,
        media: [:mticket],
        reduced: nil,
        cents: dollars_to_cents(commuter_ferry_month_price) - 1000
      }
    ]

    reduced_fares =
      fares
      |> Enum.filter(&(&1.duration in [:single_trip, :round_trip]))
      |> Enum.flat_map(fn fare ->
        reduced_price = floor_to_ten_cents(fare.cents) / 2

        [
          %{fare | cents: reduced_price, media: [:senior_card], reduced: :senior_disabled},
          %{fare | cents: reduced_price, media: [:student_card], reduced: :student}
        ]
      end)

    fares ++ reduced_fares
  end

  def mapper(["the_ride", ada_ride, premium_ride | _]) do
    [
      %Fare{
        mode: :the_ride,
        name: :ada_ride,
        media: [:senior_card],
        reduced: :senior_disabled,
        duration: :single_trip,
        cents: dollars_to_cents(ada_ride)
      },
      %Fare{
        mode: :the_ride,
        name: :premium_ride,
        media: [:senior_card],
        reduced: :senior_disabled,
        duration: :single_trip,
        cents: dollars_to_cents(premium_ride)
      }
    ]
  end

  def mapper(["foxboro", round_trip | _]) do
    for reduced <- [nil, :student, :senior_disabled] do
      %Fare{
        mode: :commuter_rail,
        name: :foxboro,
        duration: :round_trip,
        media: [:commuter_ticket, :cash],
        reduced: reduced,
        cents: dollars_to_cents(round_trip)
      }
    end
  end

  defp monthly_commuter_modes("interzone_" <> _) do
    [:bus]
  end

  defp monthly_commuter_modes(_zone) do
    [:subway, :bus, :ferry]
  end

  def mticket_price(monthly_price) when monthly_price > 1000 do
    monthly_price - 1000
  end

  defp commuter_rail_fare_name(zone) do
    case String.split(zone, "_") do
      ["zone", zone] -> {:zone, String.upcase(zone)}
      ["interzone", zone] -> {:interzone, String.upcase(zone)}
    end
  end

  defp dollars_to_cents(dollars) do
    dollars
    |> String.to_float()
    |> Kernel.*(100)
    |> round
  end

  def floor_to_ten_cents(fare), do: Float.floor(fare / 10) * 10

  # fix warning
  _ = @lint
end
