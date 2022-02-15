// ==UserScript==
// @name        garyc.me sketch tweaks
// @namespace   garyc.me by quackbarc
// @description QoL tweaks and personal mods for garyc.me/sketch
// @author      quac
// @version     1.0.0
// @match       https://garyc.me/sketch*
// @icon        https://cdn.discordapp.com/attachments/416900237618315274/932976241282252800/crung.png
// @run-at      document-body
// @grant       none
// @require     https://gist.githubusercontent.com/arantius/3123124/raw/grant-none-shim.js
// ==/UserScript==

// known bug: since i can't control the left/right arrow navigation logic
// pressing left/right even when the holder's not around would still navigate

function _getFirstGroup(regexp, str, def = null) {
    let _r = str.match(regexp);
    return _r ? _r[1] : def;
}

let lastCurrent = null;
let lastsleepPromise = null;

let dates = {}; // {id: Date || null}
let cache = {};

var settings = {}; // for referencing's sake
const db = _getFirstGroup(/db=(\d+)/, window.location.href, 0);

// private methods, /sketch/

function injectStyle() {
    GM_addStyle(`
        table {
            padding-top: 3px;
        }
        td {
            padding: 0px 3px;
        }
        td > input {
            width: 100%;
            height: 30px;
        }
        td > input#swap {
            width: 40%;
        }
        td > span#stats {
            padding: 0px 3px;
            display: block;
        }

        img[src="save.png"] {
            position: relative !important;
            left: 0px !important;
            top: 0px !important;
            opacity: .8;
        }
        img[src="save.png"]:hover {
            opacity: 1;
        }
    `);
}

// private methods, /sketch/gallery.php

function restoreSettings() {
    /* settings details
        cacheSize           the size of the sketch cache.
        showPointDensity    shows a sketch's point-to-ink density.
        invertSpace         swaps sketch loading and spacekey roles, i.e.
                            loading a sketch will immediately show the sketch
                            and pressing space will animate it
        changeHashOnArrowNav    changes the URL as you navigate with arrow keys.
                            having this as false is useful for not clogging up
                            browser history.
        miterMode           shows sketches spiky.

        do not change the defaults for yourself. instead, change your settings on
        the console, e.g. `settings.cacheSize = 100`. they'll get saved locally.
    */

    const defaultSettings = {
        cacheSize: 500,
        showPointDensity: false,
        invertSpace: false,
        changeHashOnArrowNav: false,
        miterMode: false,
    };

    var storedSettings = JSON.parse(localStorage.getItem('settings')) || {};
    var settings = {...defaultSettings, ...storedSettings};
    return settings;
}

function saveSettings() {
    localStorage.setItem("settings", JSON.stringify(settings));
}

function getURL(id, db) {
    return 'https://garyc.me/sketch/gallery.php' + (db ? `?db=${db}` : '') + `#${id}`;
}

async function copyURL() {
    await navigator.clipboard.writeText(getURL(current, db));
    await spanAlert('copied url');
}

function updateTitle(msg) {
    const id = window.current;
    const result = cache['#' + id];

    let spanTexts = [];

    if(msg) {
        spanTexts.push(msg);
    } else {
        var ink = Math.floor((result.length / 65535) * 100);
        spanTexts.push(`${ink}% ink`);
    }

    if(settings.showPointDensity) {
        let _pointDensity = getLines(result).map((e) => e.length).reduce((a, b) => a + b) * 2 / result.length;
        var pointDensity = Math.round((_pointDensity) * 10000) / 100;
        spanTexts.push(`${pointDensity}% point-to-ink ratio`);
    }
    if(dates.hasOwnProperty(id)) {
        let date = dates[id];
        let dateCaption = date != null ? `${date.toUTCString().slice(5, -7).toLowerCase()} UTC` : '...'; // gah
        spanTexts.push(dateCaption);
    }
  
    let spanText1 = spanTexts.join('<br>');
    let spanText2 = getURL(id, db);
    let span1 = (
        '<span style="flex: 1 1 auto; font-family: monospace; text-align: left;">'
        + spanText1
        + '</span>'
    );
    let span2 = (
        '<span style="flex: 0.1 1 auto; font-family: monospace; text-align: right; cursor: pointer;" onclick="copyURL()">'
        + spanText2
        + '</span>'
    );
    $("#title").html(span1 + span2);
}

async function spanAlert(msg) {
    // still not confident for this being in an arg, but not confident in putting
    // this on a separate var either
    // and i don't really care about the msg's persistence across sketch visits
    updateTitle(msg);

    let sleepPromise = lastSleepPromise = new Promise(resolve => setTimeout(resolve, 3000));
    await sleepPromise;

    if(sleepPromise === lastSleepPromise) {
        updateTitle();
    }
}

function addToCache(id, result) {
    cache['#' + id] = result.trim();

    let keys = Object.keys(cache);
    let tail = keys[0];
    if(keys.length > settings.cacheSize) {
        delete cache[tail];
    }
}

function getLines(dat) {
    var lines = dat.length > 0 ? dat.split(" ") : [];
    for(var i = 0; i < lines.length; i++) {
        var line = new Array(lines[i].length / 2 | 0);
        for(var j = 0; j < line.length * 2; j += 2) {
            line[j / 2] = parseInt(lines[i].substr(j, 2), 36);
        }
        lines[i] = line;
    }

    return lines;
}

function saveCanvas() {
    let a = document.createElement('a');
    a.href = $("#sketch")[0].toDataURL();
    a.setAttribute('download', `${current}.png`);
    a.click();
}

function saveSVG(id) {
    const parse = (p) => `${parseInt(p.slice(0, 2), 36)} ${parseInt(p.slice(2), 36)}`;
    const callback = function(el) {
        el = el.match(/.{1,4}/g) || [];
        if(el.length === 2 && (parseInt(el[0], 36) + 2594 === parseInt(el[1], 36))) {
            el[1] = el[0];
        }
        let linePath = el.map((e, i) => i ? `L ${parse(e)}` : `M ${parse(e)}`);
        return "    " + linePath.join(" ");
    }

    // converting to lines is unnecessary so we're directly parsing string data
    let dat = cache['#' + id] || '';
    let lines = dat.slice(0, dat.length - 1).split(' ');
    let path = lines.map(callback);

    var xml = (
        '<svg viewBox="0 0 800 600" xmlns="http://www.w3.org/2000/svg">\n'
        + '  <path\n'
        + '    d="\n' + path.join("\n") + '"\n'
        + '    fill="none"\n'
        + '    stroke="black"\n'
        + '    stroke-width="3px"\n'
        + '    stroke-linecap="round"\n'
        + '    stroke-linejoin="round"/>\n'
        + '</svg>'
    );

    let a = document.createElement('a');
    a.href = 'data:image/svg+xml,' + encodeURIComponent(xml);
    a.setAttribute('download', `${id}.svg`);
    a.click();
}

// date fetching logic

async function getDate(id, db = 0, minutePrecision = false) {
    function sameDate(d1, d2) {
        return d1.getDate() == d2.getDate()
          && d1.getMonth() == d2.getMonth()
          && d1.getYear() == d1.getYear();
    }

    function sameMinute(d1, d2) {
        return sameDate(d1, d2)
          && d1.getHours() == d2.getHours()
          && d1.getMinutes() == d2.getMinutes();
    }

    const getStatsURL = `https://garyc.me/sketch/getStats.php?db=${db}`;
    const maxID = window.max;

    // using fixed timestamp since Date.UTC() would offset it by a month for some reason
    var start = new Date(1262304000000); // jan 1, 2010 UTC
    var end = new Date();
    var lastMid;

    while(true) {
        var mid = new Date(((end - start) / 2) + start.getTime());

        if(lastMid && (minutePrecision ? sameMinute(lastMid, mid) : sameDate(lastMid, mid))) {
        return mid;
        }

        lastMid = mid;

        let url = getStatsURL + '&timespan=' + ((new Date() - mid) / 1000 | 0);
        let c = await fetch(url).then(r => r.text());
        let cs = parseInt(c.split(',')[0]);

        let v = maxID - cs + 1;
        if(id < v) {
        end = mid;
        }
        else if(id >= v) {
        start = mid;
        }
    }
}

async function getDateOfCurrent(minutePrecision) {
    const id = window.current;
    if(dates.hasOwnProperty(id)) {
        return;
    }

    dates[id] = null;
    updateTitle();

    dates[id] = await getDate(window.current, db, minutePrecision);
    if(window.current == id) {
        updateTitle();
    }

    return dates[id];
}

// overrides

function save(id) {
    let a = document.createElement('a');
    a.href = `https://garyc.me/sketch/getIMG.php?format=png&db=${db}&id=${id}`;
    a.setAttribute('download', `${id}.png`);
    a.click();
}

function show(id){
    var id = parseInt(id);
    if(id == 0) {
        return;
    }

    window.current = id;
    lastSleepPromise = null;

    // maxID check; can't override the arrow-key logic so this should do
    if(window.current == lastCurrent) {
        return;
    }
    lastCurrent = window.current;

    if(settings.changeHashOnArrowNav) {
        window.location.hash = id;
    }

    const sketch = window.sketch || $("#sketch");

    // using regular divs instead of loading blank PNGs
    var right = `<a href="#${id - 1}" onclick="show(${id - 1})"><img src="right.png"></a>`;
    var top = '<a onclick="hide()"><img src="top.png"></a>';
    var save = `<a onclick="save(${id})"><img src="save.png" style="width:25px; height:25px; position: absolute; top:675px; right:85px"></a>`;
    // i don't wanna deal with that save button offset atm

    let leftMax = '<div style="width: 100; height: 600; display: inline-block;"></div>'
    let leftReg = `<a href="#${id + 1}" onclick="show(${id + 1})"><img src="left.png"></a>`;
    var left = id === window.max ? leftMax : leftReg;

    let bottomStyle = [
        "display: flex;",
        "justify-content: center;",
        "text-align: center;",
        "padding: 10px 60px;",
        "height: 80px;",
        "width: 880px;",
        "font-size: 20px;",
    ].join(" ");
    var bottom = `<div id="title" style="${bottomStyle}"></div>`;

    $("#holder").html(top + left);
    $("#holder").append(sketch);
    $("#holder").append(right + bottom + save);
    $("#tiles").css({opacity: "75%"});

    sketch.show();
    sketch.on("click", () => setData(window.dat));
    reset();
    get(id);
}

function hide() {
    $("#tiles").css({opacity: 1});
    $("#holder").html("");
    window.location.hash = 0;
    window.current = lastCurrent = null;
}

function success(id) {
    let result = cache['#' + window.current];
    updateTitle();

    if(settings.invertSpace) {
       setData(result);
    } else {
       drawData(result);
    }
}

function get(id) {
    if(cache['#' + id]) {
        return success(id);
    }

    // to-do: use fetch api instead?

    $.ajax({
      url: `get.php?db=${db}&id=${id}`,
      success: function(result) {
          addToCache(id, result);
          if(window.current == id) {
              // prevent race conditions from sketch fetching
              success(id);
          }
      }
    });
}

// event listeners

function onHashChange(e) {
    let id = _getFirstGroup(/#(\d+)/, e.newURL, 0);
    if(window.current == id) {
        // prevents from being fired twice
        return;
    }

    if(id == 0) {
        hide();
    } else {
        show(id);
    }
}

async function onKeyDown(e) {
    if(!current) {
        return;
    }

    if(e.key == ' ') {
        e.preventDefault();

        if(settings.invertSpace) {
            drawData(window.dat);
        } else {
            setData(window.dat);
        }
        return;
    }

    if(e.key == '/' && e.ctrlKey) {
        e.preventDefault();
        await getDateOfCurrent(true);
        return;
    }

    if(e.key.toLowerCase() == 'c' && e.ctrlKey) {
        e.preventDefault();
        if(e.shiftKey) {
            $("#sketch")[0].toBlob(async (blob) => {
                await navigator.clipboard.write([new ClipboardItem({[blob.type]: blob})]);
                await spanAlert('copied canvas');
            });
        }
        else if(e.altKey) {
            await navigator.clipboard.writeText(dat);
            await spanAlert('copied raw data');
        }
        else {
            await copyURL();
        }
        return;
    }

    if(e.key.toLowerCase() == 's' && e.ctrlKey) {
        e.preventDefault();
        if(e.shiftKey) {
            saveSVG(current);
            await spanAlert('saved as SVG');
        }
        else if(e.altKey) {
            saveCanvas();
            await spanAlert('saved via canvas');
        }
        else {
            save(current);
            await spanAlert('saved via getIMG');
        }
        return;
    }
}

function init() {
    window.current = null;
    window.settings = settings = restoreSettings();

    $("#holder").css({
        backgroundColor: "white",
        zIndex: 1,
    });

    window.save = save;
    window.show = show;
    window.hide = hide;
    window.get = get;
    window.copyURL = copyURL;
}

function jqInit() {
    // since pixi overwrites this on a jquery .ready() listener,
    // i'll have to put this on a .ready() after it
    if(!settings.miterMode) {
        $("#sketch")[0].getContext('2d').lineJoin = "round";
    }
}

function initSketch() {  
    let saveButton = document.querySelector('img[src="save.png"]');
    saveButton.title = "Save as PNG";

    if(!settings.miterMode) {
        const canvas = window.app.view;
        const ctx = canvas.getContext('2d');
        ctx.lineJoin = "round";
    }
}


if(location.pathname == "/sketch/gallery.php") {
    document.addEventListener("DOMContentLoaded", init);
    document.addEventListener("keydown", onKeyDown);
    window.addEventListener("beforeunload", saveSettings);
    window.addEventListener("hashchange", onHashChange);

    $(document).ready(jqInit);
}

if(location.pathname == "/sketch/") {
    injectStyle();
    document.addEventListener("DOMContentLoaded", initSketch);
}
