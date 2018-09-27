import { AlgoliaAutocomplete } from "./algolia-autocomplete";
import * as GoogleMapsHelpers from './google-maps-helpers';
import * as QueryStringHelpers from "./query-string-helpers";
import geolocationPromise from "./geolocation-promise";
import * as AlgoliaResult from "./algolia-result";

export class AlgoliaAutocompleteWithGeo extends AlgoliaAutocomplete {
  constructor(id, selectors, indices, locationParams, popular, parent) {
    super(id, selectors, indices, parent);
    if(!this._parent.getParams) {
      this._parent.getParams = () => { return {}; };
    }
    this._popular = popular;
    this._loadingIndicator = document.getElementById(selectors.locationLoadingIndicator);
    this._locationParams = Object.assign(AlgoliaAutocompleteWithGeo.DEFAULT_LOCATION_PARAMS, locationParams);
    this._indices.splice(this._locationParams.position, 0, "locations");
    this._indices.push("usemylocation");
    this._indices.push("popular");
  }

  _datasetSource(index) {
    switch (index) {
      case "locations":
        return this._locationSource("locations");
      case "usemylocation":
        return this._useMyLocationSource();
      case "popular":
        return this._popularSource();
      default:
        return super._datasetSource(index);
    }
  }

  _locationSource(index) {
    return (query, callback) => {
      const bounds = {
        west: 41.3193,
        north: -71.9380,
        east: 42.8266,
        south: -69.6189
      };
      return GoogleMapsHelpers.autocomplete(query, bounds, this._locationParams.hitLimit)
              .then(results => this._onResults(callback, index, results)) .catch(err => console.error(err));
    }
  }

  _popularSource() {
    return (query, callback) => {
      const results = { popular: {hits: this._popular }}
      return this._onResults(callback, "popular", results);
    }
  }

  _useMyLocationSource() {
    return (query, callback) => {
      const results = { usemylocation: { hits: [{}] }}
      return this._onResults(callback, "usemylocation", results);
    }
  }

  minLength(index) {
    switch(index) {
      case "usemylocation":
      case "popular":
        return 0;
      default:
        return 1;
    }
  }

  maxLength(index) {
    switch(index) {
      case "usemylocation":
      case "popular":
        return 0;
      default:
        return null;
    }
  }

  onHitSelected(ev) {
    const hit = ev.originalEvent;
    const index = hit._args[1];
    switch (index) {
      case "locations":
        this._input.value = hit._args[0].description;
        this._doLocationSearch(hit._args[0].id);
        break;
      case "usemylocation":
        this.useMyLocationSearch();
        break;
      default:
        super.onHitSelected(ev);
    }
  }

  useMyLocationSearch() {
    this._input.disabled = true;
    this.setValue("Getting your location...");
    this._loadingIndicator.style.visibility = "visible";
    geolocationPromise()
      .then(pos => this._doReverseGeocodeSearch(pos))
      .catch(err => console.error(err));
  }

  _doLocationSearch(placeId) {
    return GoogleMapsHelpers.lookupPlace(placeId)
            .then(result => this._onLocationSearchResult(result))
            .catch(err => console.error("Error looking up place_id from Google Maps.", err));
  }

  _onLocationSearchResult(result) {
    return this.showLocation(result.geometry.location.lat(),
                              result.geometry.location.lng(),
                              result.formatted_address)
  }

  _doReverseGeocodeSearch({coords: {latitude, longitude}}) {
    return GoogleMapsHelpers.reverseGeocode(parseFloat(latitude), parseFloat(longitude))
             .then(result => this._onReverseGeocodeResults(result, latitude, longitude))
             .catch(err => console.error(err));
  }

  _onReverseGeocodeResults(result, latitude, longitude) {
    this._input.disabled = false;
    this.setValue(result);
    this._loadingIndicator.style.visibility = "hidden";
    this.showLocation(latitude, longitude, result);
  }

  showLocation(latitude, longitude, address) {
    const params = this._parent.getParams();
    params.latitude = latitude;
    params.longitude = longitude;
    params.address = address;
    window.Turbolinks.visit("/transit-near-me" + QueryStringHelpers.parseParams(params))
  }
}

AlgoliaAutocompleteWithGeo.DEFAULT_LOCATION_PARAMS = {
  position: 0,
  hitLimit: 5
}
