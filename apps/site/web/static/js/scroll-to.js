export default function($) {
  $ = $ || window.jQuery;

  const requestAnimationFrame = window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    function(f) { window.setTimeout(f, 15); };

  function scrollTo() {
    $("[data-scroll-to]").each(doScrollTo);
  }

  function handleScroll(ev) {
    const scrollPos = ev.target.scrollLeft;
    const containerWidth = ev.target.clientWidth;
    const $table = $(ev.target).children();
    const width = $table.width();
    const height = $table.height();

    const hideEarlier = scrollPos < 48;
    const hideLater = width - containerWidth - scrollPos < 48;

    requestAnimationFrame(function() {
      if (scrollPos < 0) {
        ev.target.scrollLeft = 0;
      }

      $table
        .toggleClass('schedule-v2-timetable-hide-earlier', hideEarlier)
        .toggleClass('schedule-v2-timetable-hide-later', hideLater);
    });
  }

  function doScrollTo(index, el) {
    const childLeft = el.offsetLeft;
    const $el = $(el);
    const childWidth = $el.outerWidth();
    const parentLeft = el.parentNode.offsetLeft;
    const firstSiblingWidth = $el.siblings("th").first().outerWidth();

    // childLeft - parentLeft scrolls the first row to the start of the
    // visible area.
    const scrollLeft = childLeft - parentLeft - firstSiblingWidth;
    $(el).parents("table").parent()
      .animate({scrollLeft}, 200)
      .on('scroll', handleScroll)
      .trigger('scroll');
  }

  $(document).on('turbolinks:load', scrollTo);
}
