import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../../Components" as Components
import "./" as LocalComponents
import "./Submodules" as Submodules

PanelWindow {
    anchors {
        top: true
        right: true
        left: true
    }

    implicitHeight: token_spacing_xl
    color: services.MatugenService.background

    RowLayout {
        anchors.fill: parent
        anchors.margins: token_spacing_sm
    
        Item {
            Layout.fillWidth: true
    
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: token_spacing_sm
                // left widgets
                LocalComponents.Workspaces {}
            }
        }
    
        Item {
            Layout.fillWidth: true
    
            Row {
                spacing: token_spacing_sm
                anchors.centerIn: parent

                LocalComponents.Mpris {}
                LocalComponents.Battery {}
                LocalComponents.SystemResourcesMini {
                    Submodules.SystemResourcePopup {
                        id: resource_popup
                        visible: false
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: resource_popup.visible = true
                        onExited: resource_popup.visible = false
                    }
                }
            }
        }
    
        Item {
            Layout.fillWidth: true
    
            Row {
                spacing: token_spacing_sm
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                LocalComponents.Clock {
                }
            }
        }
    }
}