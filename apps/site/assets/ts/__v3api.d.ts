export interface Direction {
  direction_id: DirectionId;
  headsigns: Headsign[];
}

type DirectionId = 0 | 1;

interface DirectionInfo {
  0: string;
  1: string;
}

export interface Headsign {
  name: string;
  headsign?: string;
  times: PredictedOrScheduledTime[];
  train_number: string | null;
}

export type Mode = "commuter_rail" | "subway" | "bus" | "ferry";

export interface ParkingLot {
  name: string;
  address: string | null;
  capacity: ParkingLotCapacity | null;
  payment: ParkingLotPayment | null;
  manager: ParkingLotManager | null;
  utilization?: ParkingLotUtilization | null;
  note?: string | null;
  latitude?: number;
  longitude?: number;
}

export interface ParkingLotCapacity {
  total?: number;
  accessible?: number;
  overnight: string;
  type?: string;
}

export interface ParkingLotManager {
  name?: string;
  contact?: string;
  phone: string | null;
  url: string | null;
}

export interface ParkingLotMobileApp {
  name?: string;
  id?: string;
  url: string | null;
}

export interface ParkingLotPayment {
  methods: string[];
  mobile_app?: ParkingLotMobileApp | null;
  daily_rate?: string;
  monthly_rate?: string;
}

export interface ParkingLotUtilization {
  arrive_before?: string;
  typical?: number;
}

export interface PredictedOrScheduledTime {
  delay: number;
  scheduled_time: string[] | null;
  prediction: Prediction | null;
}

export interface Prediction {
  time: string[];
  status: string | null;
  track: string | null;
}

export interface Route {
  color?: string;
  description: string;
  direction_destinations: DirectionInfo;
  direction_names: DirectionInfo;
  id: string;
  long_name: string;
  name: string;
  type: RouteType;
}

export interface EnhancedRoute extends Route {
  header: string;
  alert_count: number;
  href?: string;
}

export interface RouteWithStopsWithDirections {
  route: EnhancedRoute;
  stops_with_directions: StopWithDirections[];
}

export type RouteType = 0 | 1 | 2 | 3 | 4;

export type BikeStorageType =
  | "bike_storage_rack"
  | "bike_storage_rack_covered"
  | "bike_storage_cage";

export type FareFacilityType =
  | "fare_vending_retailer"
  | "fare_vending_machine"
  | "fare_media_assistant"
  | "fare_media_assistance_facility"
  | "ticket_window";

export type AccessibilityType =
  | "tty_phone"
  | "escalator_both"
  | "escalator_up"
  | "escalator_down"
  | "ramp"
  | "fully_elevated_platform"
  | "elevated_subplatform"
  | "unknown"
  | "accessibile"
  | "elevator"
  | "portable_boarding_lift"
  | string;

export type StopType = "station" | "stop" | "entrance";

export interface Stop {
  accessibility: AccessibilityType[];
  address: string | null;
  bike_storage: BikeStorageType[];
  closed_stop_info: ClosedStopInfo | null;
  "has_charlie_card_vendor?": boolean;
  "has_fare_machine?": boolean;
  fare_facilities: FareFacilityType[];
  id: string;
  "is_child?": boolean;
  latitude: number;
  longitude: number;
  municipality: string | null;
  name: string;
  note: string | null;
  parking_lots: ParkingLot[];
  "station?": boolean;
  type: StopType;
  distance?: string;
  href?: string;
  platform_name?: string | null;
  platform_code?: string | null;
  description?: string | null;
}

export interface ClosedStopInfo {
  reason: string;
  info_link: string;
}

export interface StopWithDirections {
  stop: Stop;
  directions: Direction[];
  distance: string;
}

export type Activity =
  | "board"
  | "exit"
  | "ride"
  | "park_car"
  | "bringing_bike"
  | "store_bike"
  | "using_wheelchair"
  | "using_escalator";

export type Lifecycle =
  | "ongoing"
  | "upcoming"
  | "ongoing_upcoming"
  | "new"
  | "unknown";

export type Priority = "high" | "low" | "system";

export interface InformedEntity {
  route: string | null;
  route_type: string | null;
  stop: string | null;
  trip: string | null;
  direction_id: DirectionId | null;
  activities: Activity[];
}

export type TimePeriodPairs = [string, string];

export interface Alert {
  id: string;
  active_period: TimePeriodPairs[];
  header: string;
  informed_entity: InformedEntity[];
  effect: string;
  severity: number;
  lifecycle: Lifecycle;
  updated_at: string;
  description: string;
  priority: Priority;
}

interface DatesNotes {
  [date: string]: string;
}

type ServiceType = "weekday" | "saturday" | "sunday" | "other";

type ServiceTypicality =
  | "unknown"
  | "typical_service"
  | "extra_service"
  | "holiday_service"
  | "planned_disruption"
  | "unplanned_disruption";

type DayInteger =
  | 1 // Monday
  | 2
  | 3
  | 4
  | 5
  | 6
  | 7; // Sunday

export interface Service {
  added_dates: string[];
  added_dates_notes: DatesNotes;
  description: string;
  end_date: string;
  id: string;
  removed_dates: string[];
  removed_dates_notes: DatesNotes;
  start_date: string;
  type: ServiceType;
  typicality: ServiceTypicality;
  valid_days: DayInteger[];
  name: string;
}

export interface ServiceWithServiceDate extends Service {
  service_date: string;
}

export interface Trip {
  id: string;
  name: string;
  headsign: string;
  direction_id: DirectionId;
  shape_id: string;
  route_pattern_id: string;
  "bikes_allowed?": boolean;
}

export interface Schedule {
  route: Route;
  trip: Trip;
  stop: Stop;
  time: string[];
  "flag?": boolean;
  "early_departure?": boolean;
  "last_stop?": boolean;
  stop_sequence: number;
  pickup_type: number;
  train_number?: string;
}

export interface Shape {
  stop_ids: string[];
  priority: number;
  polyline: string;
  name: string;
  id: string;
  direction_id: DirectionId;
}

export interface RoutePattern {
  typicality: 1 | 2 | 3 | 4;
  time_desc: string | null;
  route_id: string;
  representative_trip_id: string;
  name: string;
  id: string;
  direction_id: DirectionId;
}
