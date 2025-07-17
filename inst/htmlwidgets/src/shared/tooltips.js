/**
 * Shared tooltip and popup utilities for mapgl
 * These functions are identical across all mapgl implementations
 */

/**
 * Handle mouse leave event for tooltips
 * @param {Object} map - Map instance
 * @param {Object} tooltipPopup - Tooltip popup instance
 */
function onMouseLeaveTooltip(map, tooltipPopup) {
  map.getCanvas().style.cursor = "";
  tooltipPopup.remove();
  if (window._activeTooltip === tooltipPopup) {
    delete window._activeTooltip;
  }
}

// Export for module systems (if needed)
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    onMouseLeaveTooltip
  };
}