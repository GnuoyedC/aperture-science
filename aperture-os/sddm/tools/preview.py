#!/usr/bin/env python3
"""Development preview for the theme without SDDM.

Mocks the SDDM context objects (sddm, userModel, sessionModel, keyboard,
config, primaryScreen) and loads Main.qml in a QQuickView. Useful to test
layouts at arbitrary resolutions and to script state changes.

Requires PySide6 (pip install PySide6). Examples:

    # interactive window, password "portal" succeeds, anything else fails
    python3 tools/preview.py --size 1920x1080

    # headless screenshots of a scripted flow
    QT_QPA_PLATFORM=offscreen python3 tools/preview.py --size 2560x1440 \\
        --shot 3500:login.png --script 4000:fail --shot 4300:error.png --quit 6000

Script actions (--script MS:ACTION, repeatable):
    fail | succeed  -> emit sddm.loginFailed / loginSucceeded
    info:TEXT       -> emit sddm.informationMessage(TEXT)
    standby         -> shorten idle timeout to trigger standby immediately
    type:TEXT       -> type TEXT into the focused field, Enter = "\\n"
    key:NAME        -> send a single key (Return, Tab, Escape, Shift)
    click:X,Y       -> left click at window coordinates
    move:X,Y        -> mouse move
"""
import argparse
import configparser
import sys
from pathlib import Path

from PySide6.QtCore import (QAbstractListModel, QModelIndex, QObject, QPoint, QPointF, Qt,
                            QTimer, Property, Signal, Slot, QUrl, QByteArray, QEvent)
from PySide6.QtGui import QGuiApplication, QKeyEvent, QMouseEvent
from PySide6.QtQml import QQmlPropertyMap
from PySide6.QtQuick import QQuickView

THEME_DIR = Path(__file__).resolve().parent.parent


class Sddm(QObject):
    loginFailed = Signal()
    loginSucceeded = Signal()
    informationMessage = Signal(str)

    def __init__(self, password="portal"):
        super().__init__()
        self._password = password

    @Property(str, constant=True)
    def hostName(self):
        return "aperture-workstation"

    canPowerOff = Property(bool, lambda self: True, constant=True)
    canReboot = Property(bool, lambda self: True, constant=True)
    canSuspend = Property(bool, lambda self: True, constant=True)
    canHibernate = Property(bool, lambda self: False, constant=True)
    canHybridSleep = Property(bool, lambda self: False, constant=True)

    @Slot(str, str, int)
    def login(self, user, password, session):
        print(f"[sddm] login(user={user!r}, session={session})")
        ok = password == self._password
        QTimer.singleShot(700, self.loginSucceeded.emit if ok else self.loginFailed.emit)

    @Slot()
    def powerOff(self): print("[sddm] powerOff()")

    @Slot()
    def reboot(self): print("[sddm] reboot()")

    @Slot()
    def suspend(self): print("[sddm] suspend()")

    @Slot()
    def hibernate(self): print("[sddm] hibernate()")

    @Slot()
    def hybridSleep(self): print("[sddm] hybridSleep()")


class ListModel(QAbstractListModel):
    def __init__(self, roles, rows):
        super().__init__()
        self._roles = {Qt.UserRole + 1 + i: r for i, r in enumerate(roles)}
        self._rows = rows

    def rowCount(self, parent=QModelIndex()):
        return len(self._rows)

    def roleNames(self):
        return {k: QByteArray(v.encode()) for k, v in self._roles.items()}

    def data(self, index, role):
        if not index.isValid():
            return None
        if role == Qt.DisplayRole:
            role = Qt.UserRole + 1
        name = self._roles.get(role)
        return self._rows[index.row()].get(name) if name else None


class UserModel(ListModel):
    def __init__(self):
        super().__init__(["name", "realName", "homeDir", "icon", "needsPassword"], [
            {"name": "chell", "realName": "Chell", "homeDir": "/home/chell", "icon": "", "needsPassword": True},
            {"name": "wheatley", "realName": "", "homeDir": "/home/wheatley", "icon": "", "needsPassword": True},
        ])

    lastUser = Property(str, lambda self: "chell", constant=True)
    lastIndex = Property(int, lambda self: 0, constant=True)
    count = Property(int, lambda self: self.rowCount(), constant=True)
    disableAvatarsThreshold = Property(int, lambda self: 7, constant=True)


class SessionModel(ListModel):
    def __init__(self):
        super().__init__(["file", "type", "name", "exec", "comment"], [
            {"name": "Plasma (Wayland)", "file": "plasma.desktop"},
            {"name": "Plasma (X11)", "file": "plasmax11.desktop"},
        ])

    lastIndex = Property(int, lambda self: 0, constant=True)
    count = Property(int, lambda self: self.rowCount(), constant=True)


class Layout(QObject):
    def __init__(self, short, long):
        super().__init__()
        self._s, self._l = short, long

    shortName = Property(str, lambda self: self._s, constant=True)
    longName = Property(str, lambda self: self._l, constant=True)


class Keyboard(QObject):
    currentLayoutChanged = Signal()
    capsLockChanged = Signal()

    def __init__(self):
        super().__init__()
        self._layouts = [Layout("de", "Deutsch"), Layout("us", "English (US)")]
        self._current = 0
        self._caps = False

    def _get_current(self): return self._current

    def _set_current(self, v):
        self._current = v
        print(f"[keyboard] currentLayout = {v}")
        self.currentLayoutChanged.emit()

    currentLayout = Property(int, _get_current, _set_current, notify=currentLayoutChanged)
    layouts = Property("QVariantList", lambda self: self._layouts, constant=True)
    enabled = Property(bool, lambda self: True, constant=True)
    numLock = Property(bool, lambda self: False, constant=True)
    capsLock = Property(bool, lambda self: self._caps, notify=capsLockChanged)


def load_config(overrides):
    cp = configparser.ConfigParser(interpolation=None)
    cp.optionxform = str
    cp.read([THEME_DIR / "theme.conf", THEME_DIR / "theme.conf.user"])
    cfg = QQmlPropertyMap(None)
    for k, v in (cp["General"].items() if "General" in cp else []):
        cfg.insert(k, v)
    for o in overrides:
        k, _, v = o.partition("=")
        cfg.insert(k, v)
    return cfg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", default="1920x1080")
    ap.add_argument("--set", action="append", default=[], help="override config KEY=VALUE")
    ap.add_argument("--shot", action="append", default=[], help="MS:FILE screenshot")
    ap.add_argument("--script", action="append", default=[], help="MS:ACTION")
    ap.add_argument("--quit", type=int, default=0, help="quit after MS")
    ap.add_argument("--secondary", action="store_true", help="simulate a non-primary screen")
    args = ap.parse_args()

    app = QGuiApplication(sys.argv[:1])
    w, h = (int(x) for x in args.size.split("x"))

    sddm = Sddm()
    users, sessions, keyboard = UserModel(), SessionModel(), Keyboard()
    config = load_config(args.set)

    view = QQuickView()
    ctx = view.rootContext()
    ctx.setContextProperty("sddm", sddm)
    ctx.setContextProperty("userModel", users)
    ctx.setContextProperty("sessionModel", sessions)
    ctx.setContextProperty("keyboard", keyboard)
    ctx.setContextProperty("config", config)
    ctx.setContextProperty("primaryScreen", not args.secondary)
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(w, h)

    errors = []
    view.statusChanged.connect(lambda s: [errors.append(e.toString()) for e in view.errors()])
    view.setSource(QUrl.fromLocalFile(str(THEME_DIR / "Main.qml")))
    if view.status() == QQuickView.Error:
        for e in view.errors():
            print("QML ERROR:", e.toString())
        return 1
    view.show()
    root = view.rootObject()

    def shot(path):
        img = view.grabWindow()
        img.save(path)
        print(f"[preview] saved {path} ({img.width()}x{img.height()})")

    def send_key(key, text=""):
        for t in (QEvent.KeyPress, QEvent.KeyRelease):
            QGuiApplication.sendEvent(view, QKeyEvent(t, key, Qt.NoModifier, text))

    keys = {"Return": Qt.Key_Return, "Tab": Qt.Key_Tab, "Escape": Qt.Key_Escape,
            "Shift": Qt.Key_Shift, "Down": Qt.Key_Down}

    def mouse(kind, x, y):
        p = QPointF(x, y)
        if kind == "move":
            QGuiApplication.sendEvent(view, QMouseEvent(QEvent.MouseMove, p, p, Qt.NoButton, Qt.NoButton, Qt.NoModifier))
            return
        for t in (QEvent.MouseButtonPress, QEvent.MouseButtonRelease):
            QGuiApplication.sendEvent(view, QMouseEvent(t, p, p, Qt.LeftButton, Qt.LeftButton, Qt.NoModifier))

    def action(a):
        print(f"[preview] action {a}")
        name, _, arg = a.partition(":")
        if name == "fail":
            sddm.loginFailed.emit()
        elif name == "succeed":
            sddm.loginSucceeded.emit()
        elif name == "info":
            sddm.informationMessage.emit(arg)
        elif name == "standby":
            root.enterStandby()
        elif name == "type":
            for ch in arg.replace("\\n", "\n"):
                if ch == "\n":
                    send_key(Qt.Key_Return)
                else:
                    send_key(0, ch)
        elif name == "key":
            send_key(keys[arg])
        elif name in ("click", "move"):
            x, y = (float(v) for v in arg.split(","))
            mouse(name, x, y)
        elif name == "phase":
            print("[preview] phase =", root.property("phase"), "standby =", root.property("standby"))

    for s in args.shot:
        ms, _, path = s.partition(":")
        QTimer.singleShot(int(ms), lambda p=path: shot(p))
    for s in args.script:
        ms, _, a = s.partition(":")
        QTimer.singleShot(int(ms), lambda a=a: action(a))
    if args.quit:
        QTimer.singleShot(args.quit, app.quit)
    ret = app.exec()
    # Tear down the scene before the Python mock objects are collected,
    # otherwise bindings re-evaluate against null context properties.
    view.setSource(QUrl())
    del view
    return ret


if __name__ == "__main__":
    sys.exit(main())
