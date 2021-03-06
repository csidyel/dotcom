import React, { ReactElement } from "react";
import ServiceOption from "./ServiceOption";
import {
  ServiceOptGroupName,
  ServiceByOptGroup
} from "../../../helpers/service";

interface Props {
  group: ServiceOptGroupName;
  label: string;
  services: ServiceByOptGroup[];
  multipleWeekdays: boolean;
}

const ServiceOptGroup = ({
  group,
  label,
  services,
  multipleWeekdays
}: Props): ReactElement<HTMLElement> | null =>
  services.length === 0 ? null : (
    <optgroup key={group} label={label}>
      {services.map(service => (
        <ServiceOption
          key={service.service.id + service.servicePeriod}
          service={service.service}
          group={group}
          servicePeriod={service.servicePeriod}
          multipleWeekdays={multipleWeekdays}
        />
      ))}
    </optgroup>
  );
export default ServiceOptGroup;
