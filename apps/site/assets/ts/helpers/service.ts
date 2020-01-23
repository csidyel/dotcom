import { Service } from "../__v3api";
import { shortDate } from "./date";

const formattedDate = (date: Date): string => shortDate(date);

export type ServiceOptGroupName = "current" | "holiday" | "future";

export interface ServiceByOptGroup {
  type: ServiceOptGroupName;
  servicePeriod: string;
  service: Service;
}

export type ServicesKeyedByGroup = {
  [key in ServiceOptGroupName]: ServiceByOptGroup[]
};

export const groupByType = (
  acc: ServicesKeyedByGroup,
  currService: ServiceByOptGroup
): ServicesKeyedByGroup => {
  const currentServiceType: ServiceOptGroupName = currService.type;
  const updatedGroup = [...acc[currentServiceType], currService];
  return { ...acc, [currentServiceType]: updatedGroup };
};

export const groupServiceByDate = (
  service: Service,
  currDate: Date = new Date()
): ServiceByOptGroup[] => {
  const {
    start_date: startDate,
    end_date: endDate,
    added_dates: addedDates,
    added_dates_notes: addedDatesNotes,
    typicality
  } = service;

  if (typicality === "holiday_service") {
    return addedDates.map(addedDate => ({
      type: "holiday" as ServiceOptGroupName,
      servicePeriod: `${addedDatesNotes[addedDate]}, ${formattedDate(
        new Date(addedDate)
      )}`,
      service
    }));
  }

  const serviceDateTime = currDate.getTime();
  const startDateObject = new Date(startDate);
  const startDateTime = startDateObject.getTime();
  const endDateObject = new Date(endDate);
  const endDateTime = endDateObject.getTime();

  if (serviceDateTime >= startDateTime && serviceDateTime <= endDateTime) {
    return [
      {
        type: "current",
        servicePeriod: `ends ${formattedDate(endDateObject)}`,
        service
      }
    ];
  }

  if (serviceDateTime < startDateTime) {
    return [
      {
        type: "future",
        servicePeriod: `starts ${formattedDate(startDateObject)}`,
        service
      }
    ];
  }

  return [
    {
      type: "future",
      servicePeriod: `${formattedDate(startDateObject)} to ${formattedDate(
        endDateObject
      )}`,
      service
    }
  ];
};

export const optGroupNames: ServiceOptGroupName[] = [
  "current",
  "holiday",
  "future"
];

const optGroupTitles: { [key in ServiceOptGroupName]: string } = {
  current: "Current Schedules",
  holiday: "Holidays",
  future: "Future Schedules"
};

export const groupedServiceOptLabel = (
  groupName: ServiceOptGroupName,
  groupedServices: ServiceByOptGroup[]
): string => {
  // TODO: Validate whether all services in a group will have the same rating description and service period. Also check correspondence between service period and rating start/end dates.
  let label = optGroupTitles[groupName];

  if (groupName !== "holiday") {
    if (groupedServices[0].service.rating_description) {
      label += ` (${groupedServices[0].service.rating_description}, ${
        groupedServices[0].servicePeriod
      })`;
    } else {
      label += ` (${groupedServices[0].servicePeriod})`;
    }
  }
  return label;
};

export const hasMultipleWeekdaySchedules = (services: Service[]): boolean =>
  services.filter(
    service =>
      service.type === "weekday" && service.typicality !== "holiday_service"
  ).length > 1;
