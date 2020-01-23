import { groupServiceByDate } from "../service";
import { Service } from "../../__v3api";

const service: Service = {
  added_dates: [],
  added_dates_notes: {},
  description: "Weekday schedule",
  start_date: "2019-06-25",
  end_date: "2019-06-25",
  id: "BUS319-D-Wdy-02",
  removed_dates: [],
  removed_dates_notes: {},
  type: "weekday",
  typicality: "typical_service",
  valid_days: [1, 2, 3, 4, 5],
  name: "weekday",
  rating_start_date: "2019-06-25",
  rating_end_date: "2019-06-25",
  rating_description: "Test"
};

const currentService = {
  ...service,
  start_date: "2019-06-25",
  end_date: "2019-07-28"
};

const upcomingService = {
  ...service,
  start_date: "2019-07-01",
  end_date: "2019-07-30"
};

const testDate = new Date("2019-06-25");

describe("groupServiceByDate", () => {
  it("groups current schedules with the proper service period", () => {
    const groupedService = groupServiceByDate(currentService, testDate);
    expect(groupedService).toEqual([
      {
        type: "current",
        servicePeriod: "ends Jul 28",
        service: currentService
      }
    ]);
  });

  it("groups upcoming schedules as future with proper service period", () => {
    const groupedService = groupServiceByDate(upcomingService, testDate);
    expect(groupedService).toEqual([
      {
        type: "future",
        servicePeriod: "starts Jul 1",
        service: upcomingService
      }
    ]);
  });

  it("groups holiday schedules with proper service period", () => {
    const holidayService: Service = {
      ...service,
      added_dates: ["2019-06-25"],
      added_dates_notes: { "2019-06-25": "Some Holiday" },
      typicality: "holiday_service"
    };
    const groupedService = groupServiceByDate(holidayService);
    expect(groupedService).toEqual([
      {
        type: "holiday",
        servicePeriod: "Some Holiday, Jun 25",
        service: holidayService
      }
    ]);
  });

  it("marks future schedules as future", () => {
    const groupedService = groupServiceByDate(
      {
        ...service,
        start_date: "2119-01-01",
        end_date: "2119-01-02"
      },
      testDate
    );
    expect(groupedService).toEqual([
      {
        type: "future",
        servicePeriod: "starts Jan 1",
        service: {
          ...service,
          start_date: "2119-01-01",
          end_date: "2119-01-02"
        }
      }
    ]);
  });
});
