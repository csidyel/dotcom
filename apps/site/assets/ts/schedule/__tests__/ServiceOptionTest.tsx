import React from "react";
import renderer from "react-test-renderer";
import { createReactRoot } from "../../app/helpers/testUtils";
import { Service } from "../../__v3api";
import { serviceDays } from "../components/schedule-finder/ServiceOption";

const service: Service = {
  added_dates: [],
  added_dates_notes: {},
  description: "Weekday schedule",
  end_date: "2019-06-25",
  id: "BUS319-D-Wdy-02",
  removed_dates: [],
  removed_dates_notes: {},
  start_date: "2019-06-25",
  type: "weekday",
  typicality: "typical_service",
  valid_days: [1, 2, 3, 4, 5],
  name: "weekday",
  rating_start_date: "2019-02-25",
  rating_end_date: "2019-10-25",
  rating_description: "Test"
};

describe("serviceDays", () => {
  it("returns an empty string for weekends", () => {
    const saturday: Service = {
      ...service,
      description: "Saturday schedule",
      type: "saturday",
      valid_days: [6]
    };
    expect(serviceDays(saturday)).toBe("");

    const sunday: Service = {
      ...service,
      description: "Sunday schedule",
      type: "sunday",
      valid_days: [7]
    };
    expect(serviceDays(sunday)).toBe("");
  });

  it("returns a single day in parentheses", () => {
    const friday: Service = { ...service, valid_days: [5] };
    expect(serviceDays(friday)).toBe("Friday");
  });

  it.each`
    valid_days   | day1           | day2
    ${[1, 2, 3]} | ${"Monday"}    | ${"Wednesday"}
    ${[3, 4, 5]} | ${"Wednesday"} | ${"Friday"}
  `(
    "returns consecutive days as $day1 - $day2",
    ({ valid_days, day1, day2 }) => {
      const days: Service = { ...service, valid_days };
      expect(serviceDays(days)).toBe(`${day1} - ${day2}`);
    }
  );

  it("returns consecutive days Monday to Friday as 'Weekday'", () => {
    const dailyService: Service = { ...service, valid_days: [1, 2, 3, 4, 5] };
    expect(serviceDays(dailyService)).not.toBe("Monday - Friday");
    expect(serviceDays(dailyService)).toBe("Weekday");
  });

  it("lists all non-consecutive days", () => {
    const monWedFri: Service = { ...service, valid_days: [1, 3, 5] };
    expect(serviceDays(monWedFri)).toBe("Monday, Wednesday, Friday");
  });
});
