pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    // events: [{ date: "2026-06-10", text: "..." }]   reminders: [{ ts: <ms>, text: "..." }]
    property var events: []
    property var reminders: []

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/state.json"
        onLoaded: {
            try {
                const d = JSON.parse(text())
                root.events = d.events || []
                root.reminders = d.reminders || []
                root.launches = d.launches || ({})
            } catch (e) { /* first run */ }
        }
        Component.onCompleted: reload()
    }

    function save() {
        file.setText(JSON.stringify({ events: root.events, reminders: root.reminders, launches: root.launches }))
    }
    function addEvent(date, text) {
        const e = root.events.slice(); e.push({ date: date, text: text }); root.events = e; save()
    }
    function removeEvent(date, text) {
        root.events = root.events.filter(x => !(x.date === date && x.text === text)); save()
    }
    function eventsFor(date) { return root.events.filter(x => x.date === date) }
    function addReminder(ts, text) {
        const r = root.reminders.slice(); r.push({ ts: ts, text: text }); root.reminders = r; save()
    }
    function removeReminder(ts, text) {
        root.reminders = root.reminders.filter(x => !(x.ts === ts && x.text === text)); save()
    }


    // appId -> { count: N, last: <ms> }
    property var launches: ({})

    function recordLaunch(id) {
        const l = root.launches
        const cur = l[id] || { count: 0, last: 0 }
        l[id] = { count: cur.count + 1, last: Date.now() }
        root.launches = l
        save()
    }
    function frecency(id) {
        const e = root.launches[id]
        if (!e) return 0
        const days = (Date.now() - e.last) / 86400000
        const recency = 1 / (1 + days)        // 1.0 today, decays with age
        return e.count * (0.4 + 0.6 * recency)
    }
}