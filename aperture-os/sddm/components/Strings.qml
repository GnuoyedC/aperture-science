import QtQuick

// All user-visible texts live here.
//
// `lab` holds the in-world system texts (English by default to keep the
// Aperture aesthetic). The language tables hold the functional UI texts and
// may also override any lab key. Add a language by adding a table and setting
// `language=<code>` in theme.conf ("auto" uses the system locale).
QtObject {
    id: strings

    property string language: "de"

    readonly property string effectiveLanguage: {
        const code = language === "auto" ? Qt.locale().name.substring(0, 2) : language
        return tables[code] !== undefined ? code : "en"
    }

    // Locale used for date formatting.
    readonly property string localeName: tables[effectiveLanguage]["locale"]

    readonly property var lab: ({
        "brand.top": "APERTURE",
        "brand.bottom": "LABORATORIES",
        "boot.title1": "APERTURE LABORATORIES",
        "boot.title2": "AUTOMATED TESTING FACILITY",
        "boot.step1": "INITIALIZING TEST CHAMBER",
        "boot.step2": "CALIBRATING PORTAL",
        "boot.step3": "VERIFYING TEST SUBJECT",
        "boot.ok": "OK",
        "boot.welcome": "WELCOME, TEST SUBJECT",
        "boot.skip": "PRESS ANY KEY TO SKIP",
        "panel.header": "TEST CHAMBER ACCESS",
        "panel.awaiting": "AWAITING TEST SUBJECT",
        "panel.auth": "VERIFYING TEST SUBJECT",
        "panel.failed": "TEST SEQUENCE FAILED",
        "panel.success": "TEST SEQUENCE INITIALIZED",
        "standby.title": "STANDBY TEST MODE",
        "hud.online": "SYSTEM ONLINE",
        "hud.host": "HOST",
        "hud.status": [
            "PORTAL FIELD STABLE",
            "CHAMBER PRESSURE NOMINAL",
            "SUBJECT TELEMETRY OK",
            "TURRET CALIBRATION 100%",
            "EMANCIPATION GRILL ACTIVE",
            "ENRICHMENT CENTER READY"
        ],
        "footer": "PLEASE DO NOT UNPLUG THE TESTING EQUIPMENT"
    })

    readonly property var tables: ({
        "de": {
            "locale": "de_DE",
            "username": "Benutzername",
            "password": "Passwort",
            "login": "Anmelden",
            "loggingIn": "Anmeldung läuft …",
            "session": "Sitzung",
            "layout": "Tastaturlayout",
            "powerOff": "Ausschalten",
            "powerOffHint": "System herunterfahren",
            "reboot": "Neustart",
            "rebootHint": "System neu starten",
            "suspend": "Ruhezustand",
            "suspendHint": "In den Ruhezustand versetzen",
            "hibernate": "Tiefschlaf",
            "hibernateHint": "Sitzung auf Festplatte sichern",
            "cancel": "Abbrechen",
            "system": "System",
            "failed": "Ungültiger Benutzername oder Passwort.",
            "noUser": "Bitte einen Benutzernamen eingeben.",
            "timeout": "Keine Antwort vom Anmeldedienst. Bitte erneut versuchen.",
            "success": "Willkommen, Testsubjekt.",
            "capsLock": "Feststelltaste ist aktiv",
            "showPassword": "Passwort anzeigen",
            "selectUser": "Benutzer wählen",
            "standbyHint": "Warten auf Aktivität …",
            "skipHint": "Beliebige Taste zum Überspringen"
        },
        "en": {
            "locale": "en_GB",
            "username": "Username",
            "password": "Password",
            "login": "Log in",
            "loggingIn": "Logging in …",
            "session": "Session",
            "layout": "Keyboard layout",
            "powerOff": "Shut down",
            "powerOffHint": "Power off the system",
            "reboot": "Restart",
            "rebootHint": "Restart the system",
            "suspend": "Suspend",
            "suspendHint": "Suspend to RAM",
            "hibernate": "Hibernate",
            "hibernateHint": "Suspend to disk",
            "cancel": "Cancel",
            "system": "System",
            "failed": "Invalid credentials.",
            "noUser": "Please enter a username.",
            "timeout": "The login service did not respond. Please try again.",
            "success": "Welcome, test subject.",
            "capsLock": "Caps Lock is on",
            "showPassword": "Show password",
            "selectUser": "Select user",
            "standbyHint": "Waiting for activity …",
            "skipHint": "Press any key to skip"
        }
    })

    // Lookup: language table first (allows overriding lab texts), then the
    // shared lab table, then English, finally the key itself.
    function tr(key) {
        const t = tables[effectiveLanguage]
        if (t[key] !== undefined)
            return t[key]
        if (lab[key] !== undefined)
            return lab[key]
        if (tables["en"][key] !== undefined)
            return tables["en"][key]
        return key
    }
}
