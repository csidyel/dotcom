import React from "react";
import renderer from "react-test-renderer";
import DirectionComponent from "../components/Direction";
import { createReactRoot } from "../../app/helpers/testUtils";
import {
  Direction,
  Headsign,
  PredictedOrScheduledTime,
  Route
} from "../../__v3api";

/* eslint-disable typescript/camelcase */
const time: PredictedOrScheduledTime = {
  scheduled_time: ["4:30", " ", "PM"],
  prediction: null,
  delay: 0
};

const headsign: Headsign = {
  name: "Headsign",
  times: [time],
  train_number: null
};

const direction: Direction = {
  direction_id: 0,
  headsigns: [headsign]
};

const route: Route = {
  alert_count: 0,
  direction_destinations: ["Outbound Destination", "Inbound Destination"],
  direction_names: ["Outbound", "Inbound"],
  id: "route-id",
  name: "Route Name",
  header: "Route Header",
  long_name: "Route Long Name",
  description: "Route Description",
  type: 1
};

it("it renders", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <DirectionComponent
        direction={{
          ...direction,
          headsigns: [1, 2].map(i => ({ ...headsign, name: `Headsign ${i}` }))
        }}
        route={route}
        stopId="stop-id"
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("returns null if direction has no schedules", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <DirectionComponent
        direction={{ ...direction, headsigns: [] }}
        route={route}
        stopId="stop-id"
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it does not display the route direction for commuter rail", () => {
  createReactRoot();
  const headsigns = [1, 2].map(i => ({
    ...headsign,
    name: `Headsign ${i}`,
    train_number: `59${i}`
  }));
  const tree = renderer
    .create(
      <DirectionComponent
        direction={{ ...direction, headsigns }}
        route={{ ...route, type: 2 }}
        stopId="stop-id"
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it does not display the direction destination when there is only one headsign", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <DirectionComponent
        direction={direction}
        route={route}
        stopId="stop-id"
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});
