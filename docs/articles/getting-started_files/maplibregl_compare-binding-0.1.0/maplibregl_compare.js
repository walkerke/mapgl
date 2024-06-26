HTMLWidgets.widget({

  name: 'maplibregl_compare',

  type: 'output',

  factory: function(el, width, height) {

    // Add default CSS for full screen
    // const css = `
    //   body, html {
    //     margin: 0;
    //     padding: 0;
    //     width: 100%;
    //     height: 100%;
    //     overflow: hidden;
    //   }
    //   #${el.id} {
    //     position: absolute;
    //     top: 0;
    //     bottom: 0;
    //     left: 0;
    //     right: 0;
    //     width: 100%;
    //     height: 100%;
    //   }
    // `;
    // const style = document.createElement('style');
    // style.type = 'text/css';
    // style.innerHTML = css;
    // document.getElementsByTagName('head')[0].appendChild(style);

        const css = `
          .maplibre-map-container {
            width: 100%;
            height: inherit;
            position: absolute;
          }
        `;

        const style = document.createElement('style');
        style.type = 'text/css';
        style.innerHTML = css;
        document.getElementsByTagName('head')[0].appendChild(style);

    return {
      renderValue: function(x) {
        if (typeof maplibregl === 'undefined') {
          console.error("Maplibre GL JS is not loaded.");
          return;
        }
        if (typeof maplibregl.Compare === 'undefined') {
          console.error("Maplibre GL Compare plugin is not loaded.");
          return;
        }

        el.innerHTML = `
          <div id="${x.elementId}-before" class="maplibre-map-container"></div>
          <div id="${x.elementId}-after" class="maplibre-map-container"></div>
        `;

        var beforeMap = new maplibregl.Map({
          container: `${x.elementId}-before`,
          style: x.map1.style,
          center: x.map1.center,
          zoom: x.map1.zoom,
          bearing: x.map1.bearing,
          pitch: x.map1.pitch,
          accessToken: x.map1.access_token
        });

        var afterMap = new maplibregl.Map({
          container: `${x.elementId}-after`,
          style: x.map2.style,
          center: x.map2.center,
          zoom: x.map2.zoom,
          bearing: x.map2.bearing,
          pitch: x.map2.pitch,
          accessToken: x.map2.access_token
        });

        new maplibregl.Compare(beforeMap, afterMap, `#${x.elementId}`, {
          mousemove: x.mousemove,
          orientation: x.orientation
        });

        // Ensure both maps resize correctly
        beforeMap.on('load', function() {
          beforeMap.resize();
        });

        afterMap.on('load', function() {
          afterMap.resize();
        });
      },

      resize: function(width, height) {
        // Code to handle resizing if necessary
      }
    };
  }
});
