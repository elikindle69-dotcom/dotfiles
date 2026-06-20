pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property int low_battery_threshold: config_low_battery_threshold
    readonly property real percentage: UPower.displayDevice.percentage * 100
    readonly property bool is_low: percentage <= low_battery_threshold
    readonly property bool is_charging: UPower.displayDevice.state === 1

    readonly property string state_label: {
        if (is_charging) return "Charging"
        if (is_low) return "Low battery"
        return Math.round(percentage) + "%"
    }

    signal lowBatteryChanged(bool is_low)
    signal stateChanged()

    onIs_lowChanged: lowBatteryChanged(is_low)
    onIs_chargingChanged: stateChanged()
}
