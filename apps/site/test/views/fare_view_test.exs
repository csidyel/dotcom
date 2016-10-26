defmodule Site.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Site.FareView
  alias Fares.Fare

  describe "fare_duration_summary/1" do
    test "fare duration is '1 Month' for a monthly fare" do
      assert fare_duration_summary(:month) == "1 Month"
    end

     test "fare duration is 'Round Trip' for a round-trip fare" do
       assert fare_duration_summary(:round_trip) == "Round Trip"
     end

     test "fare duration is 'One Way' for a one-way fare" do
       assert fare_duration_summary(:single_trip) == "One Way"
     end
  end

  test "fare_duration/1" do
    assert fare_duration(%Fare{duration: :single_trip}) == "One Way"
    assert fare_duration(%Fare{duration: :round_trip}) == "Round Trip"
    assert fare_duration(%Fare{duration: :month}) == "Monthly Pass"
    assert fare_duration(%Fare{duration: :month, pass_type: :mticket}) == "Monthly Pass on mTicket App"
    assert fare_duration(%Fare{mode: :subway, duration: :single_trip}) == "Single Ride"
    assert fare_duration(%Fare{mode: :bus, duration: :single_trip}) == "Single Ride"
  end

  describe "description/1" do
    test "fare description for one way CR is for commuter rail only" do
      fare = %Fare{duration: :single_trip, mode: :commuter}
      assert description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for CR round trip is for commuter rail only" do
      fare = %Fare{duration: :round_trip, mode: :commuter}
      assert description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for month is describes the modes it can be used on" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, mode: :commuter}

      assert description(fare) ==
        "Valid for one calendar month of unlimited travel on Commuter Rail from " <>
        "Zones 1A-5 as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
    end

    test "fare description for month mticket describes where it can be used" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, pass_type: :mticket, mode: :commuter}

      assert description(fare) ==
        "Valid for one calendar month of travel on the commuter rail from zones 1A-5 only."
    end
  end

  describe "eligibility/1" do
    test "returns eligibility information for student fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: :student}) =~
        "Middle and high school students are eligible"
    end

    test "returns eligibility information for senior fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: :senior_disabled}) =~
        "Those who are 65 years of age or older"
    end

    test "returns eligibility information for adult fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: nil}) =~
        "Those who are 12 years of age or older qualify for Adult fare pricing."
    end
  end

  describe "vending_machine_stations/0" do
    test "generates a list of links to stations with fare vending machines" do
      content = vending_machine_stations |> Phoenix.HTML.safe_to_string

      assert content =~ "place-north"
      assert content =~ "place-sstat"
      assert content =~ "place-bbsta"
      assert content =~ "place-brntn"
      assert content =~ "place-forhl"
      assert content =~ "place-jfk"
      assert content =~ "Lynn"
      assert content =~ "place-mlmnl"
      assert content =~ "place-portr"
      assert content =~ "place-qnctr"
      assert content =~ "place-rugg"
      assert content =~ "Worcester"
    end
  end

  describe "charlie_card_stations/0" do
    test "generates a list of links to stations where a customer can buy a CharlieCard" do
      content = charlie_card_stations |> Phoenix.HTML.safe_to_string

      assert content =~ "place-alfcl"
      assert content =~ "place-armnl"
      assert content =~ "place-asmnl"
      assert content =~ "place-bbsta"
      assert content =~ "64000"
      assert content =~ "place-forhl"
      assert content =~ "place-harsq"
      assert content =~ "place-north"
      assert content =~ "place-ogmnl"
      assert content =~ "place-pktrm"
      assert content =~ "place-rugg"
    end
  end
end
