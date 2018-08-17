export default class DatePickerInput {
  constructor(options) {
    this.selectors = options.selectors;
    this.onUpdateCallback = options.onUpdateCallback;
    this.init();
  }

  init() {
    this.dateInput = $(`#${this.selectors.dateEl.input}`); // Must use JQuery for the datepicker plugin
    const dateLabel = document.getElementById(this.selectors.dateEl.label);
    const actualMonth = parseInt(
      document.getElementById(this.selectors.month).value,
      10
    );
    const minAllowedDate = this.dateInput.data("min-date");
    const maxAllowedDate = this.dateInput.data("max-date");
    const date = new Date(
      document.getElementById(this.selectors.year).value,
      actualMonth - 1,
      document.getElementById(this.selectors.day).value
    );

    dateLabel.setAttribute("data-date", DatePickerInput.getShortDate(date));

    this.updateDateFormatToShort = this.updateDateFormatToShort.bind(this);
    this.updateDateFormatToLong = this.updateDateFormatToLong.bind(this);
    this.dateInput.datepicker({
      outputFormat: DatePickerInput.getDateFormatbyMediaQuery(),
      onUpdate: this.updateDate.bind(this),
      min: minAllowedDate,
      max: maxAllowedDate
    });

    // disable clicking on the month to change the grid type
    $(".datepicker-month").off();

    // remove fast-skip buttons
    $(".datepicker-month-fast-next").remove();
    $(".datepicker-month-fast-prev").remove();

    // replace default datepicker arrow icons
    $(".datepicker-calendar")
      .find(".glyphicon")
      .removeClass("glyphicon")
      .addClass("fa");
    $(".datepicker-calendar")
      .find(".glyphicon-triangle-right")
      .removeClass("glyphicon-triangle-right")
      .addClass("fa-caret-right");
    $(".datepicker-calendar")
      .find(".glyphicon-triangle-left")
      .removeClass("glyphicon-triangle-left")
      .addClass("fa-caret-left");

    $(document).on("click", `#${this.selectors.dateEl.input}`, ev => {
      ev.preventDefault();
      ev.stopPropagation();
      $(`#${this.selectors.dateEl.input}`).datepicker("show"); // jQuery plugin that requires this syntax
    });

    window
      .matchMedia("(min-width: 1344px)")
      .addListener(this.updateDateFormatToLong);

    window
      .matchMedia("(min-width: 1087px) and (max-width: 1344px)")
      .addListener(this.updateDateFormatToShort);

    window
      .matchMedia("(min-width: 800px) and (max-width: 1087px)")
      .addListener(this.updateDateFormatToShort);

    window
      .matchMedia("(min-width: 544px) and (max-width: 800px)")
      .addListener(this.updateDateFormatToLong);

    window
      .matchMedia("(max-width: 544px)")
      .addListener(this.updateDateFormatToShort);

    this.dateInput.datepicker("setDate", date);
    this.dateInput.datepicker("update");
  }

  static getDateFormatbyMediaQuery() {
    if (window.matchMedia("(min-width: 1344px)").matches) {
      return "EEEE, MMMM dd, yyyy";
    }
    if (
      window.matchMedia("(min-width: 544px) and (max-width: 800px)").matches
    ) {
      return "EEEE, MMMM dd, yyyy";
    }
    return "EE, MMMM dd, yyyy";
  }

  updateDateFormatToShort(e) {
    return e.matches ? this.setDatePickerFormat("EE, MMMM dd, yyyy") : false;
  }

  updateDateFormatToLong(e) {
    return e.matches ? this.setDatePickerFormat("EEEE, MMMM dd, yyyy") : false;
  }

  setDatePickerFormat(format) {
    this.dateInput.datepicker("outputFormat", format);
    this.dateInput.datepicker("update");
  }

  updateDate(datepickerDate) {
    const date = new Date(datepickerDate);
    const dateLabel = document.getElementById(this.selectors.dateEl.label);
    const ariaMessage = dateLabel.getAttribute("aria-label").split(", ")[3];
    dateLabel.setAttribute("data-date", DatePickerInput.getShortDate(date));
    dateLabel.setAttribute("aria-label", `${datepickerDate}, ${ariaMessage}`);
    this.updateDateSelects(date);

    this.dateInput.datepicker("hide");
    this.onUpdateCallback();
  }

  updateDateSelects(date) {
    const year = date.getFullYear().toString();
    const month = (date.getMonth() + 1).toString();
    const day = date.getDate().toString();
    this.updateSelect({ month });
    this.updateSelect({ day });
    this.updateSelect({ year });
  }

  updateSelect(select) {
    const type = Object.keys(select)[0];
    const options = document.getElementById(this.selectors[type]);
    const currentOpt = options.querySelector("option[selected='selected']");
    const newOpt = options.querySelector(`option[value='${select[type]}']`);
    currentOpt.removeAttribute("selected");
    if (!newOpt) {
      options.append(
        $(
          `<option value="${select[type]}" selected="selected">${
            select[type]
          }</option>`
        )
      );
    } else {
      newOpt.setAttribute("selected", "selected");
    }
  }

  static getShortDate(date) {
    const options = {
      year: "2-digit",
      month: "numeric",
      day: "numeric"
    };
    return date.toLocaleDateString("en-US", options);
  }
}
