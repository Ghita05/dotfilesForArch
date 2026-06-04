pragma Singleton
import QtQuick

QtObject {
    // "", "volume", "network", "battery", "calendar"
    property string active: ""
    function toggle(name) { active = (active === name) ? "" : name }
    function open(name)  { active = name }
    function close()     { active = "" }
}