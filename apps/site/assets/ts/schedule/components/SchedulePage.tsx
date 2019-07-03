import React, { ReactElement } from "react";
import { SchedulePageData } from "./__schedule";
import DirectionSelector from "./DirectionSelector";
import PDFSchedules from "./PDFSchedules";
import Connections from "./Connections";
import ContentTeasers from "./ContentTeasers";
import HoursOfOperation from "./HoursOfOperation";
import Fares from "./Fares";
import UpcomingHolidays from "./UpcomingHolidays";
import ScheduleNote from "./ScheduleNote";
import ScheduleFinder from "./ScheduleFinder";

interface Props {
  schedulePageData: SchedulePageData;
}

const SchedulePage = ({
  schedulePageData: {
    connections,
    pdfs,
    teasers,
    hours,
    fares,
    holidays,
    fare_link: fareLink,
    route,
    route_patterns: routePatterns,
    schedule_note: scheduleNote,
    services,
    stops,
    direction_id: directionId
  }
}: Props): ReactElement<HTMLElement> => (
  <>
    <DirectionSelector
      directionId={directionId}
      route={route}
      routePatterns={routePatterns}
    />
    {!!scheduleNote && (
      <ScheduleNote
        className="m-schedule-page__schedule-notes--desktop"
        scheduleNote={scheduleNote}
      />
    )}
    {route.type !== 0 && route.type !== 1 && (
      <div className="schedule-finder--desktop">
        <ScheduleFinder
          route={route} // don't show for subway
          services={services}
          stops={stops}
          directionId={directionId}
        />
      </div>
    )}
    <ContentTeasers teasers={teasers} />
    <PDFSchedules pdfs={pdfs} />
    <Connections connections={connections} />
    <Fares fares={fares} fareLink={fareLink} routeType={route.type} />
    <HoursOfOperation hours={hours} />
    <UpcomingHolidays holidays={holidays} />
  </>
);
export default SchedulePage;
