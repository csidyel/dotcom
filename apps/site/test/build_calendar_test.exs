defmodule BuildCalendarTest do
  use ExUnit.Case, async: true

  import BuildCalendar
  alias BuildCalendar.{Calendar, Day}

  import Phoenix.HTML, only: [safe_to_string: 1]

  defp url_fn(keywords) do
    inspect keywords
  end

  describe "build/2" do
    test "days starts on Sunday" do
      date = ~D[2017-01-02]
      calendar = build(date, Util.service_date(), [], &url_fn/1)
      first_day = List.first(calendar.days)
      assert first_day == %BuildCalendar.Day{
        date: ~D[2017-01-01],
        month_relation: :current,
        selected?: false,
        holiday?: false,
        url: ~s([date: "2017-01-01", date_select: nil])
      }
    end

    test "days at the end of the previous month are invisible" do
      date = ~D[2017-05-01]
      calendar = build(date, Util.service_date(), [], &url_fn/1)
      first_day = List.first(calendar.days)
      assert first_day.month_relation == :previous
      assert Enum.at(calendar.days, 1).month_relation == :current # 2017-05-01
    end

    test "calendars always have a number of days divisible by 7 and end in the next month" do
      for date <- [~D[2017-01-02], ~D[2017-05-01], ~D[2017-07-01]] do
        calendar = build(date, Util.service_date(), [], &url_fn/1)
        assert Integer.mod(length(calendar.days), 7) == 0
        assert List.last(calendar.days).month_relation == :next
      end
    end

    test "calendars that end on saturday have an extra week at the end" do
      date = ~D[2017-09-15]
      calendar = build(date, Util.service_date(), [], &url_fn/1)
      assert length(calendar.days) == 7 * 6
      assert List.last(calendar.days).month_relation == :next
    end

    test "calendars that end on friday have 8 extra days" do
      date = ~D[2017-03-15]
      calendar = build(date, Util.service_date(), [], &url_fn/1)
      assert length(calendar.days) == 7 * 6
      assert List.last(calendar.days).month_relation == :next
    end

    test "days that are holidays are marked" do
      holiday = Enum.random(Holiday.Repo.all)
      calendar = build(holiday.date, Util.service_date(), [holiday], &url_fn/1)
      for day <- calendar.days do
        if day.date == holiday.date do
          assert day.holiday?
        else
          refute day.holiday?
        end
      end
    end

    test "Holidays are included in calendar struct" do
      date =  ~D[2017-01-02]
      holidays = Holiday.Repo.holidays_in_month(date)
      calendar = build(date, Util.service_date(), holidays, &url_fn/1)
      assert calendar.holidays == holidays
    end

    test "selected is marked" do
      selected = Util.service_date()
      calendar = build(selected, Timex.shift(selected, days: -1), [], &url_fn/1)
      for day <- calendar.days do
        if day.date == selected do
          assert day.selected?
        else
          refute day.selected?
        end
      end
    end

    test "today is marked" do
      service_date = Util.service_date()
      calendar = build(Timex.shift(service_date, days: 1), service_date, [], &url_fn/1)
      for day <- calendar.days do
        if day.date == service_date do
          assert day.today?
        else
          refute day.today?
        end
      end
    end

    test "previous_month_url is nil if the date is the current month" do
      service_date = Util.service_date()
      calendar = build(service_date, service_date, [], &url_fn/1)
      assert calendar.previous_month_url == nil
    end

    test "previous_month_url is the first day of the previous month" do
      next_month = Timex.shift(Util.service_date(), months: 1)
      first_of_month = Timex.beginning_of_month(Util.service_date())
      calendar = build(next_month, Util.service_date(), [], &url_fn/1)
      assert calendar.previous_month_url == url_fn(date: Timex.format!(first_of_month, "{ISOdate}"))
    end

    test "next_month_url is the first day of the next month" do
      service_date = Util.service_date()
      first_of_next_month = Util.service_date()
      |> Timex.shift(months: 1)
      |> Timex.beginning_of_month
      calendar = build(service_date, service_date, [], &url_fn/1)
      assert calendar.next_month_url == url_fn(date: Timex.format!(first_of_next_month, "{ISOdate}"))
    end
  end

  describe "Calendar.weeks/1" do
    test "breaks the days of the calendar into week blocks" do
      service_date = Util.service_date()
      calendar = build(service_date, service_date, [], &url_fn/1)
      weeks = Calendar.weeks(calendar)
      assert length(weeks) == length(calendar.days) / 7
      for week <- weeks do
        # 7 days in a week
        assert length(week) == 7
        # each week starts on sunday
        assert Timex.weekday(List.first(week).date) == 7 # sunday
      end
    end
  end

  describe "Day.td/1" do
    test "has no content for previous months" do
      actual = Day.td(
        %Day{
          date: ~D[2017-01-01],
          month_relation: :previous
        })
      assert safe_to_string(actual) == ~s(<td class="schedule-weekend"></td>)
    end

    test "includes the day of the month, along with a link" do
      actual = Day.td(
        %Day{
          date: ~D[2017-02-01],
          url: "url"
        })
      assert safe_to_string(actual) == ~s(<td><a href="url">1</a></td>)
    end

    test "if the day is selected, adds a class" do
      actual = Day.td(
        %Day{
          date: ~D[2000-12-01],
          selected?: true,
          url: ""
        })
      assert safe_to_string(actual) =~ ~s(class="schedule-selected")
    end

    test "if the day is a weekend, adds a class" do
      sunday = Day.td(
        %Day{
          date: ~D[2017-01-01],
          url: ""
        })
      saturday = Day.td(
        %Day{
          date: ~D[2016-12-31],
          url: ""
        })
      assert safe_to_string(sunday) =~ ~s(class="schedule-weekend")
      assert safe_to_string(saturday) =~ ~s(class="schedule-weekend")
    end

    test "if the day is next month, adds a class" do
      actual = Day.td(
        %Day{
          date: ~D[2000-12-01],
          month_relation: :next,
          url: ""
        })
      assert safe_to_string(actual) =~ ~s(class="schedule-next-month")
    end

    test "if selected is a weekend, includes both classes" do
      actual = Day.td(
        %Day{
          date: ~D[2017-01-01],
          selected?: true,
          url: ""
        })
      assert safe_to_string(actual) =~ ~s(class="schedule-weekend schedule-selected")
    end
  end
end
