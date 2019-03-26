import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";
import { Stop } from "../../__v3api";
import RouteSidebarHeader from "../components/RouteSidebarHeader";
import { createReactRoot } from "../../app/helpers/testUtils";

/* eslint-disable typescript/camelcase */

const stop: Stop = {
  accessibility: ["wheelchair"],
  address: "123 Main St., Boston MA",
  bike_storage: [],
  closed_stop_info: null,
  fare_facilities: [],
  "has_charlie_card_vendor?": false,
  "has_fare_machine?": false,
  id: "stop-id",
  "is_child?": false,
  latitude: 41.0,
  longitude: -71.0,
  name: "Stop Name",
  note: null,
  parking_lots: [],
  "station?": true,
  distance: "238 ft",
  href: "/stops/stop-id"
};

it("it renders with no stop selected", () => {
  createReactRoot();

  const tree = renderer
    .create(
      <RouteSidebarHeader
        showPill={false}
        selectedStop={undefined}
        dispatch={() => {}}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders with a stop selected", () => {
  createReactRoot();

  const tree = renderer
    .create(
      <RouteSidebarHeader showPill selectedStop={stop} dispatch={() => {}} />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it does not show a pill when showPill is false", () => {
  createReactRoot();

  const tree = renderer
    .create(
      <RouteSidebarHeader
        showPill={false}
        selectedStop={stop}
        dispatch={() => {}}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it deselects a stop when the pill is clicked", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <RouteSidebarHeader showPill selectedStop={stop} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__pill").simulate("click");
  expect(mockDispatch).toHaveBeenCalledWith({
    payload: { stopId: null },
    type: "CLICK_STOP_PILL"
  });
});

it("it deselects a stop when the pill is selected via keyboard ENTER", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <RouteSidebarHeader showPill selectedStop={stop} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__pill").simulate("keyPress", { key: "Enter" });
  expect(mockDispatch).toHaveBeenCalledWith({
    payload: { stopId: null },
    type: "CLICK_STOP_PILL"
  });
});

it("it deselects a stop when the pill is selected via a different keyboard event", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <RouteSidebarHeader showPill selectedStop={stop} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__pill").simulate("keyPress", { key: "Tab" });
  expect(mockDispatch).not.toHaveBeenCalled();
});
