// Photo pixels of a light source (PNG cut by tools/make_*_overlays.py) placed at
// a rect in source-art px (1672x941); the caller only animates `opacity`.
import QtQuick

Image {
    required property var wp
    required property var r          // { src, x, y, w, h } in source px
    x: wp.mapX((wp.mirror ? r.x + r.w : r.x) / 1672)
    y: wp.mapY(r.y / 941)
    width: r.w / 1672 * wp.dispW
    height: r.h / 941 * wp.dispH
    source: r.src
    mirror: wp.mirror
    smooth: true
    asynchronous: true
}
