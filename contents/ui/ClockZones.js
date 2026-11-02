.pragma library

// "Europe/London=LON;America/New_York=NYC" <-> [{ tz, code }]
function parse(str) {
    var out = []
    String(str || "").split(";").forEach(function (item) {
        var p = item.split("=")
        var tz = p[0].trim()
        if (tz !== "" && out.every(function (z) { return z.tz !== tz }))
            out.push({ tz: tz, code: cleanCode(p[1] || defaultCode(tz)) || defaultCode(tz) })
    })
    return out
}

// At most 3 characters (an emoji counts as one), upper case; ";" and "=" are the storage separators
function cleanCode(s) {
    return Array.from(String(s).replace(/[=;]/g, "").trim()).slice(0, 3).join("").toUpperCase()
}

// Emoji and symbols read badly rotated, so labels containing them stay upright
function hasEmoji(s) {
    return Array.from(String(s)).some(function (ch) { return ch.codePointAt(0) >= 0x2190 })
}

function join(zones) {
    return zones.map(function (z) { return z.tz + "=" + z.code }).join(";")
}

function city(tz) {
    return tz.split("/").pop().replace(/_/g, " ")
}

var known = {
    New_York: "NYC", Los_Angeles: "LAX", Chicago: "CHI", Denver: "DEN", Toronto: "TOR", Mexico_City: "MEX",
    Sao_Paulo: "SAO", Buenos_Aires: "BUE", Vancouver: "YVR", London: "LON", Paris: "PAR", Berlin: "BER",
    Madrid: "MAD", Rome: "ROM", Amsterdam: "AMS", Zurich: "ZRH", Stockholm: "STO", Moscow: "MOW",
    Istanbul: "IST", Dubai: "DXB", Kolkata: "KOL", Karachi: "KHI", Dhaka: "DAC", Bangkok: "BKK",
    Singapore: "SIN", Hong_Kong: "HKG", Shanghai: "SHA", Tokyo: "TYO", Seoul: "SEL", Sydney: "SYD",
    Melbourne: "MEL", Auckland: "AKL", Honolulu: "HNL", Anchorage: "ANC", Cairo: "CAI",
    Johannesburg: "JNB", Lagos: "LOS", Nairobi: "NBO", Kuala_Lumpur: "KUL", Jakarta: "JKT", Manila: "MNL",
    Taipei: "TPE", Lisbon: "LIS", Dublin: "DUB", Vienna: "VIE", Warsaw: "WAW", Athens: "ATH", Kyiv: "KYV"
}

function defaultCode(tz) {
    var c = tz.split("/").pop()
    return known[c] || c.replace(/[^A-Za-z]/g, "").slice(0, 3).toUpperCase()
}

// "+0530" -> seconds
function offsetSeconds(z) {
    var m = /^([+-])(\d\d)(\d\d)$/.exec(z || "")
    return m ? (m[1] === "-" ? -1 : 1) * (+m[2] * 3600 + +m[3] * 60) : NaN
}

// Hour difference to local time: +9h, -5h, 0h, +5.5h
function hours(diffSeconds) {
    var h = Math.round(diffSeconds / 36) / 100
    return (h > 0 ? "+" : "") + h + "h"
}

// Wall clock time of a zone from its UTC offset
function clock(nowMs, offsetSec, use24) {
    var d = new Date(nowMs + offsetSec * 1000)
    var h = d.getUTCHours(), m = d.getUTCMinutes()
    var mm = (m < 10 ? "0" : "") + m
    if (use24) return (h < 10 ? "0" : "") + h + ":" + mm
    return (h % 12 || 12) + ":" + mm + (h < 12 ? "am" : "pm")
}

// Calendar day difference to local: -1, 0, +1
function dayShift(nowMs, offsetSec, localSec) {
    var a = new Date(nowMs + offsetSec * 1000), b = new Date(nowMs + localSec * 1000)
    return Date.UTC(a.getUTCFullYear(), a.getUTCMonth(), a.getUTCDate()) / 864e5
         - Date.UTC(b.getUTCFullYear(), b.getUTCMonth(), b.getUTCDate()) / 864e5
}
