import React from "react";
import { Headsign, Route } from "../../../__v3api";
import {
  timeForCommuterRail,
  statusForCommuterRail
} from "../../../helpers/prediction-helpers";

interface Props {
  headsigns: Headsign[];
  route: Route | null;
}

const capitalize = (string: string): string =>
  string[0].toUpperCase() + string.slice(1);

const StopPredictions = ({ headsigns, route }: Props): JSX.Element => {
  let predictions: JSX.Element[];
  const liveHeadsigns = headsigns.filter(
    headsign =>
      headsign.times[0] &&
      headsign.times[0].prediction &&
      headsign.times[0].prediction.time
  );

  if (route && route.type === 2) {
    // Display at most 1 prediction for Commuter Rail
    predictions = liveHeadsigns.slice(0, 1).map(headsign => {
      const time = headsign.times[0];
      const prediction = time.prediction!;

      return (
        <div key={headsign.name}>
          <div className="m-schedule-diagram__cr-prediction">
            {timeForCommuterRail(
              time,
              "m-schedule-diagram__cr-prediction-time"
            )}
          </div>
          <div className="m-schedule-diagram__cr-prediction-details">
            {`${headsign.name} · `}
            {headsign.train_number ? `Train ${headsign.train_number} · ` : ""}
            {prediction.track ? `Track ${prediction.track} · ` : ""}
            {statusForCommuterRail(headsign.times[0])}
          </div>
        </div>
      );
    });
  } else {
    predictions = liveHeadsigns.map(headsign => (
      <div key={headsign.name} className="m-schedule-diagram__prediction">
        <div>{headsign.name}</div>
        <div className="m-schedule-diagram__prediction-time">
          {capitalize(headsign.times[0].prediction!.time.join(" "))}
        </div>
      </div>
    ));
  }

  return <div className="m-schedule-diagram__predictions">{predictions}</div>;
};

export default StopPredictions;
