import React, { ReactElement } from "react";
import { LineDiagramStop, RouteStop, RouteStopRoute } from "../__schedule";
import {
  alertIcon,
  TooltipWrapper,
  modeIcon,
  parkingIcon,
  accessibleIcon
} from "../../../helpers/icon";
import { Alert, Route } from "../../../__v3api";

interface Props {
  stop: LineDiagramStop;
  onClick: (stop: RouteStop) => void;
  color: string;
  isOrigin?: boolean;
  isDestination?: boolean;
}

const filteredConnections = (
  connections: RouteStopRoute[]
): RouteStopRoute[] => {
  const firstCRIndex = connections.findIndex(
    connection => connection.type === 2
  );
  const firstFerryIndex = connections.findIndex(
    connection => connection.type === 4
  );

  return connections.filter(
    (connection, index) =>
      (connection.type !== 2 && connection.type !== 4) ||
      (connection.type === 2 && index === firstCRIndex) ||
      (connection.type === 4 && index === firstFerryIndex)
  );
};

const busBackgroundClass = (connection: Route): string =>
  connection.name.startsWith("SL") ? "u-bg--silver-line" : "u-bg--bus";

const connectionName = (connection: Route): string => {
  if (connection.type === 3) {
    return connection.name.startsWith("SL")
      ? `Silver Line ${connection.name}`
      : `Route ${connection.name}`;
  }

  if (connection.type === 2) {
    return "Commuter Rail";
  }

  return connection.name;
};

const StopConnections = (connections: RouteStopRoute[]): JSX.Element => (
  <div className="m-schedule-diagram__connections">
    {connections.map((connectingRoute: Route) => (
      <TooltipWrapper
        key={connectingRoute.id}
        href={`/schedules/${connectingRoute.id}/line`}
        tooltipText={connectionName(connectingRoute)}
        tooltipOptions={{
          placement: "bottom",
          animation: "false"
        }}
      >
        {connectingRoute.type === 3 ? (
          <span
            key={connectingRoute.id}
            className={`c-icon__bus-pill--small m-schedule-diagram__connection ${busBackgroundClass(
              connectingRoute
            )}`}
          >
            {connectingRoute.name}
          </span>
        ) : (
          <span
            key={connectingRoute.id}
            className="m-schedule-diagram__connection"
          >
            {modeIcon(connectingRoute.id)}
          </span>
        )}
      </TooltipWrapper>
    ))}
  </div>
);

const MaybeAlert = (alerts: Alert[]): ReactElement<HTMLElement> | null => {
  const highPriorityAlerts = alerts.filter(alert => alert.priority === "high");
  if (highPriorityAlerts.length === 0) return null;
  return (
    <>
      {alertIcon("c-svg__icon-alerts-triangle")}
      <span className="sr-only">Service alert or delay</span>
      &nbsp;
    </>
  );
};

const StopFeatures = (routeStop: RouteStop): JSX.Element => (
  <div className="m-schedule-diagram__features">
    {routeStop.stop_features.includes("parking_lot") ? (
      <TooltipWrapper
        tooltipText="Parking"
        tooltipOptions={{ placement: "bottom" }}
      >
        {parkingIcon(
          "c-svg__icon-parking-default m-schedule-diagram__feature-icon"
        )}
      </TooltipWrapper>
    ) : null}
    {routeStop.stop_features.includes("access") ? (
      <TooltipWrapper
        tooltipText="Accessible"
        tooltipOptions={{ placement: "bottom" }}
      >
        {accessibleIcon(
          "c-svg__icon-acessible-default m-schedule-diagram__feature-icon"
        )}
      </TooltipWrapper>
    ) : null}
    {routeStop.route!.type === 2 && routeStop.zone && (
      <span className="c-icon__cr-zone m-schedule-diagram__feature-icon">{`Zone ${
        routeStop.zone
      }`}</span>
    )}
  </div>
);

const StopBranchLabel = (stop: RouteStop): JSX.Element | null =>
  stop["is_terminus?"] && !!stop.branch && !!stop.route ? (
    <strong className="u-small-caps">
      {stop.route.id.startsWith("Green")
        ? `Green Line ${stop.route.id.split("-")[1]}`
        : stop.name}
      {stop.route.type === 2 ? " Line" : " Branch"}
    </strong>
  ) : null;

const StopGraphic = (isOrigin = false, isTerminus = false): JSX.Element => {
  let yPosition = "-32px";
  if (isTerminus) {
    yPosition = isOrigin ? "-66px" : "32px";
  }
  return (
    <svg viewBox="0 10 10 10" className="m-schedule-diagram__line-stop">
      <circle r={`${isTerminus ? "5" : "4"}`} cx="50%" cy={yPosition} />
    </svg>
  );
};

const SingleStop = ({
  stop,
  onClick,
  color,
  isOrigin,
  isDestination
}: Props): ReactElement<HTMLElement> | null => {
  const {
    stop_data: stopData,
    route_stop: routeStop,
    alerts: stopAlerts
  } = stop;
  let stopClassNames = "m-schedule-diagram__stop";
  if (isOrigin) {
    stopClassNames += " m-schedule-diagram__stop--origin";
  }
  if (isDestination) {
    stopClassNames += " m-schedule-diagram__stop--destination";
  }
  if (stopData.some(sd => sd.type === "terminus")) {
    stopClassNames += " m-schedule-diagram__stop--terminus";
  }
  return (
    <div className={stopClassNames}>
      <div style={{ color: `#${color}` }} className="m-schedule-diagram__lines">
        {stopData.some(sd => sd.type === "merge") ? (
          <div className="m-schedule-diagram__line m-schedule-diagram__line--stop">
            {StopGraphic()}
          </div>
        ) : (
          stopData.map((sd, sdIndex) => (
            <div
              key={`${sd.type}-${sd.branch}`}
              className={`m-schedule-diagram__line m-schedule-diagram__line--${
                sd.type
              }`}
            >
              {sdIndex > 0
                ? sdIndex + 1 === stopData.length &&
                  StopGraphic(isOrigin, sd.type === "terminus")
                : sd.type !== "line" &&
                  StopGraphic(isOrigin, sd.type === "terminus")}
            </div>
          ))
        )}
      </div>
      <div className="m-schedule-diagram__content">
        <div className="m-schedule-diagram__card">
          <div className="m-schedule-diagram__card-left">
            <div className="m-schedule-diagram__stop-name">
              {StopBranchLabel(routeStop)}
              <a href={`/stops/${routeStop.id}`}>
                <h4>
                  {MaybeAlert(stopAlerts)} {routeStop.name}{" "}
                </h4>
              </a>
            </div>
            {StopConnections(filteredConnections(routeStop.connections))}
          </div>
          {StopFeatures(routeStop)}
        </div>
        {!isDestination && (
          <div className="m-schedule-diagram__footer">
            <button
              className="btn btn-link"
              type="button"
              onClick={() => onClick(routeStop)}
            >
              View schedule
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default SingleStop;
