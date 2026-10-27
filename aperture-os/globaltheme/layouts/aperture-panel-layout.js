// Aperture OS - optional panel layout ("Aperture system bar").
// Applied ONLY via `install.sh --apply-layout` (which backs up your current
// plasma-org.kde.plasma.desktop-appletsrc first). The Global Theme itself never
// touches your panels.
//
// One bottom panel per screen, no top panel (reference setup, Session 2):
//  ┌──────────────────────────────────────────────────────────────────────┐
//  │ ◉ │ 1 2 3 4 │  task manager …                   │ tray │ 14:37 │ ▭ │
//  └──────────────────────────────────────────────────────────────────────┘
// ◉ = Aperture launcher (aperture-os.launcher, Meta opens it via X-Plasma-Provides; Kickoff if not installed)
// Panels are floating. "Translucent" is not scriptable (panel.opacity is read-only):
// install.sh writes panelOpacity=2 for the printed panel ids into plasmashellrc.

const LAUNCHER = knownWidgetTypes.indexOf("aperture-os.launcher") >= 0
    ? "aperture-os.launcher" : "org.kde.plasma.kickoff";

// remove existing panels
for (const p of panels()) p.remove();

for (let screen = 0; screen < screenCount; ++screen) {
    const panel = new Panel("org.kde.panel");
    if (screen > 0) panel.screen = screen;
    panel.location = "bottom";
    panel.height = 45;
    panel.floating = true;
    panel.hiding = "none";

    const launcher = panel.addWidget(LAUNCHER);
    launcher.currentConfigGroup = ["General"];
    launcher.writeConfig("icon", "aperture-os");

    const pager = panel.addWidget("org.kde.plasma.pager");
    pager.currentConfigGroup = ["General"];
    pager.writeConfig("displayedText", "Number");
    pager.writeConfig("showWindowIcons", false);

    const tasks = panel.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", [
        "preferred://browser",
        "applications:org.kde.dolphin.desktop",
        "applications:kitty.desktop",
    ]);

    panel.addWidget("org.kde.plasma.marginsseparator");
    panel.addWidget("org.kde.plasma.systemtray");

    const clock = panel.addWidget("org.kde.plasma.digitalclock");
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", true);
    clock.writeConfig("dateFormat", "isoDate");
    clock.writeConfig("use24hFormat", 2);

    panel.addWidget("org.kde.plasma.minimizeall");

    print("panel " + panel.id + " -> screen " + panel.screen + " (" + LAUNCHER + ")\n");
}
