import { doWhenGoogleMapsIsReady} from './google-maps-loaded';
import * as QueryStringHelpers from "./query-string-helpers";
import hogan from "hogan.js";
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo"
import { AlgoliaAutocomplete } from "./algolia-autocomplete"
import { featureIcon } from "./algolia-result";

export function init() {
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(() => { new AlgoliaHomepageSearch(); })
  });
}

export class AlgoliaHomepageSearch {
  constructor() {
    this._input = document.getElementById(AlgoliaHomepageSearch.SELECTORS.input);
    this._controller = null;
    this._autocomplete = null;
    this.bind();
    if (this._input) {
      this.init();
    }
  }

  init() {
    this._resetButton = document.getElementById(AlgoliaHomepageSearch.SELECTORS.resetButton);
    this._input.value = "";
    this._controller = new Algolia(AlgoliaHomepageSearch.INDICES, AlgoliaHomepageSearch.PARAMS);
    this._autocomplete = new AlgoliaAutocompleteWithGeo(AlgoliaHomepageSearch.SELECTORS,
                                                        Object.keys(AlgoliaHomepageSearch.INDICES),
                                                        {},
                                                        AlgoliaHomepageSearch.LOCATION_PARAMS,
                                                        this);
    this._autocomplete.renderFooterTemplate = this._renderFooterTemplate;
    this._autocomplete.renderHeaderTemplate = this._renderHeaderTemplate;
    this._autocomplete.showLocation = this._showLocation;
    this._controller.addWidget(this._autocomplete);
    this.addEventListeners();
    this._toggleResetButton(false);
  }

  _showLocation(latitude, longitude, address) {
    const params = this.getParams();
    params.latitude = latitude;
    params.longitude = longitude;
    params.address = address;
    window.Turbolinks.visit("/transit-near-me" + QueryStringHelpers.parseParams(params))
  }

  bind() {
    this._renderFooterTemplate = this._renderFooterTemplate.bind(this);
    this._renderHeaderTemplate = this._renderHeaderTemplate.bind(this);
    this._showLocation = this._showLocation.bind(this);
    this.reset = this.reset.bind(this);
    this.onKeyup = this.onKeyup.bind(this);
  }

  addEventListeners() {
    Object.keys(AlgoliaHomepageSearch.SHOWMOREPARAMS).forEach(key => {
      window.jQuery(document).on("click", `#show-more--${key}`, () => {
        this._onClickShowMore(key);
      });
    });

    window.jQuery(document).off("keyup", "#" + this._input.id, this.onKeyup);
    window.jQuery(document).on("keyup", "#" + this._input.id, this.onKeyup);

    this._resetButton.removeEventListener("click", this.reset);
    this._resetButton.addEventListener("click", this.reset);
  }

  reset(ev) {
    this._input.value = "";
    this._toggleResetButton(false);
    this._controller.reset();
  }

  _toggleResetButton(show) {
    this._resetButton.style.display = show ? "block" : "none";
  }

  onKeyup(ev) {
    this._toggleResetButton(this._input.value != "");
  }

  _renderHeaderTemplate(indexName) {
    const showMore = this._renderShowMoreTemplate(indexName);
    return `<div class="c-search-bar__results-header">${AlgoliaAutocomplete.DEFAULT_HEADERS[indexName]}${showMore}</div>`;
  }

  _renderFooterTemplate(indexName) {
    if (indexName == "locations") {
      return '<div class="c-search-result__google">' +
                document.getElementById("powered-by-google-logo").innerHTML +
             '</div>';
    }
    return "";
  }

  _renderShowMoreTemplate(indexName) {
    return `<span id="show-more--${indexName}" class="c-search-bar__autocomplete--show-more">Show more</span>`;
  }

  _onClickShowMore(indexName) {
    Turbolinks.visit(`/search?query=${this._input.value}&facets=${AlgoliaHomepageSearch.SHOWMOREPARAMS[indexName].facets}&showmore=${AlgoliaHomepageSearch.SHOWMOREPARAMS[indexName].showMore}`);
  }

  getParams() {
    return {
      from: "homepage-search",
      query: this._input.value
    };
  }
}

AlgoliaHomepageSearch.INDICES = {
  routes: {
    indexName: "routes",
    query: ""
  },
  stops: {
    indexName: "stops",
    query: ""
  },
  pagesdocuments: {
    indexName: "drupal",
    query: ""
  },
}

AlgoliaHomepageSearch.SELECTORS = {
  input: "homepage-search__input",
  container: "homepage-search__container",
  locationLoadingIndicator: "homepage-search__loading-indicator",
  resetButton: "homepage-search__reset"
}

AlgoliaHomepageSearch.SHOWMOREPARAMS = {
  locations: {
    facets: "locations"
  },
  stops: {
    facets: "stops,facet-station,facet-stop",
    showMore: "stops"
  },
  routes: {
    facets: "lines-routes,subway,bus,commuter-rail,ferry",
    showMore: "routes"
  },
  pagesdocuments: {
    facets: "pages-parent,page,document",
    showMore: "pagesdocuments"
  },
}

AlgoliaHomepageSearch.PARAMS = {
  stops: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[]]
  },
  routes: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[]]
  },
  pagesdocuments: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[
      "_content_type:page",
      "_content_type:search_result",
      "_content_type:landing_page",
      "_content_type:person",
      "_content_type:project",
      "_content_type:project_update",
      "search_api_datasource:entity:file"
    ]]
  },
}

AlgoliaHomepageSearch.LOCATION_PARAMS = {
  position: 3,
  hitLimit: 2
}
