pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal networksUpdated()

    // Properties matching original NetworkManager.qml / Iwd.qml API
    property var deviceStatus: null
    property var wirelessInterfaces: []
    property var ethernetInterfaces: []
    property bool isConnected: false
    property bool connecting: false
    property string activeInterface: "wlan0"
    property string activeConnection: ""
    property bool wifiEnabled: true
    readonly property bool scanning: false

    readonly property list<AccessPoint> networks: []
    property AccessPoint active: null

    property list<string> savedConnections: []
    property list<string> savedConnectionSsids: []

    property var wirelessDeviceDetails: null
    property var ethernetDeviceDetails: null
    property list<var> ethernetDevices: []
    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    property list<var> activeProcesses: []
    property var pendingConnection: null

    readonly property alias connectionCheckTimer: connectionCheckTimer
    readonly property alias immediateCheckTimer: immediateCheckTimer

    Timer {
        id: connectionCheckTimer
        interval: 1000
    }

    Timer {
        id: immediateCheckTimer
        property int checkCount: 0
        interval: 1000
    }

    // Timer for periodic polling
    Timer {
        id: pollTimer
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            refreshStatus();
            getNetworks();
        }
    }

    function getWifiStatus(callback) {
        runCommand(["nmcli", "radio", "wifi"], result => {
            if (result.success) {
                const enabled = result.output.trim() === "enabled";
                root.wifiEnabled = enabled;
                if (callback) callback(enabled);
            } else {
                if (callback) callback(root.wifiEnabled);
            }
        });
    }

    function enableWifi(enabled, callback) {
        const state = enabled ? "on" : "off";
        runCommand(["nmcli", "radio", "wifi", state], result => {
            if (result.success) {
                root.wifiEnabled = enabled;
                if (callback) callback(result);
            } else {
                if (callback) callback(result);
            }
        });
    }

    function toggleWifi(callback) {
        enableWifi(!root.wifiEnabled, callback);
    }

    function rescanWifi() {
        runCommand(["nmcli", "device", "wifi", "rescan"], result => {
            getNetworks();
        });
    }

    function scanWirelessNetworks(interfaceName, callback) {
        runCommand(["nmcli", "device", "wifi", "rescan"], result => {
            if (callback) callback(result);
            getNetworks();
        });
    }

    function getNetworks(callback) {
        runCommand(["nmcli", "-t", "-f", "active,ssid,signal,security,bssid", "dev", "wifi"], result => {
            if (!result.success) {
                if (callback) callback([]);
                return;
            }

            const parsed = parseGetNetworks(result.output);

            // Sync with root.networks list
            const rNetworks = root.networks;
            const newMap = new Map();
            for (const n of parsed) {
                newMap.set(n.ssid, n);
            }

            // Remove networks that no longer exist
            for (let i = rNetworks.length - 1; i >= 0; i--) {
                const rn = rNetworks[i];
                if (!newMap.has(rn.ssid)) {
                    rNetworks.splice(i, 1);
                    rn.destroy();
                }
            }

            // Update or add networks
            const existingMap = new Map();
            for (const rn of rNetworks) {
                existingMap.set(rn.ssid, rn);
            }

            for (const [ssid, network] of newMap) {
                const match = existingMap.get(ssid);
                if (match) {
                    match.lastIpcObject = network;
                } else {
                    rNetworks.push(apComp.createObject(root, {
                        lastIpcObject: network
                    }));
                }
            }

            root.networksUpdated();
            root.active = root.networks.find(n => n.active) ?? null;

            if (callback) callback(root.networks);
        });
    }

    function refreshStatus(callback) {
        runCommand(["nmcli", "-t", "-f", "active,ssid,signal,security,bssid", "dev", "wifi"], result => {
            if (!result.success) {
                root.isConnected = false;
                root.activeConnection = "";
                for (const n of root.networks) {
                    if (n.active) {
                        n.lastIpcObject = {
                            active: false,
                            strength: n.strength,
                            frequency: n.frequency,
                            ssid: n.ssid,
                            bssid: n.bssid,
                            security: n.security
                        };
                    }
                }
                root.active = null;
                root.networksUpdated();
                if (callback) callback({ connected: false, interface: root.activeInterface, connection: "" });
                return;
            }

            const lines = result.output.split('\n');
            let connected = false;
            let activeSsid = "";
            let activeBssid = "";
            let activeStrength = 0;
            let activeSecurity = "";

            for (const line of lines) {
                if (!line.trim()) continue;
                const normalizedLine = line.replace(/\\:/g, '__COLON__');
                const parts = normalizedLine.split(':');
                if (parts.length < 5) continue;

                const active = parts[0].trim() === "yes" || parts[0].trim() === "*";
                if (active) {
                    connected = true;
                    activeSsid = parts[1].replace(/__COLON__/g, ':').trim();
                    activeStrength = parseInt(parts[2].trim()) || 0;
                    activeSecurity = parts[3].replace(/__COLON__/g, ':').trim();
                    activeBssid = parts[4].replace(/__COLON__/g, ':').trim();
                    break;
                }
            }

            root.isConnected = connected;
            root.activeConnection = activeSsid;

            // Update active state of all networks
            for (const n of root.networks) {
                const isCurrentActive = connected && n.ssid === activeSsid;
                if (n.active !== isCurrentActive || isCurrentActive) {
                    n.lastIpcObject = {
                        active: isCurrentActive,
                        strength: isCurrentActive ? activeStrength : n.strength,
                        frequency: n.frequency,
                        ssid: n.ssid,
                        bssid: isCurrentActive ? activeBssid : n.bssid,
                        security: n.security
                    };
                }
            }

            root.networksUpdated();
            root.active = root.networks.find(n => n.active) ?? null;

            if (callback) {
                callback({
                    connected: connected,
                    interface: root.activeInterface,
                    connection: activeSsid
                });
            }
        });
    }

    function loadSavedConnections(callback) {
        runCommand(["nmcli", "-t", "-f", "name,type", "connection", "show"], result => {
            if (!result.success) {
                root.savedConnections = [];
                root.savedConnectionSsids = [];
                if (callback) callback([]);
                return;
            }

            const lines = result.output.split('\n');
            const ssids = [];
            for (const line of lines) {
                if (!line.trim()) continue;
                const parts = line.split(':');
                if (parts.length >= 2 && parts[1].includes("wireless")) {
                    ssids.push(parts[0].replace(/\\:/g, ':'));
                }
            }
            root.savedConnections = ssids;
            root.savedConnectionSsids = ssids;
            if (callback) callback(ssids);
        });
    }

    function hasSavedProfile(ssid) {
        if (!ssid) return false;
        const ssidLower = ssid.toLowerCase().trim();
        return root.savedConnectionSsids.some(s => s.toLowerCase().trim() === ssidLower);
    }

    function connectingSsid() {
        return root.connecting && root.pendingConnection ? root.pendingConnection.ssid : "";
    }

    function forgetNetwork(ssid, callback) {
        if (!ssid) return;
        runCommand(["nmcli", "connection", "delete", ssid], result => {
            loadSavedConnections();
            if (callback) callback(result);
        });
    }

    function connectToNetworkWithPasswordCheck(ssid, isSecure, callback, bssid) {
        if (hasSavedProfile(ssid)) {
            connectToNetwork(ssid, "", bssid, callback);
        } else if (isSecure) {
            if (callback) callback({ success: false, needsPassword: true });
        } else {
            connectToNetwork(ssid, "", bssid, callback);
        }
    }

    function connectToNetwork(ssid, password, bssid, callback) {
        let cmd = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password) {
            cmd.push("password", password);
        }
        if (bssid) {
            cmd.push("bssid", bssid);
        }

        runCommand(cmd, result => {
            Qt.callLater(() => {
                refreshStatus();
                loadSavedConnections();
            }, 1000);

            if (callback) {
                callback(result);
            }
        });
    }

    function disconnectFromNetwork() {
        runCommand(["nmcli", "device", "disconnect", root.activeInterface], result => {
            refreshStatus();
        });
    }

    // Ethernet Stubs
    function getEthernetInterfaces(callback) {
        root.ethernetInterfaces = [];
        root.ethernetDevices = [];
        if (callback) callback([]);
    }

    function connectEthernet(connectionName, interfaceName, callback) {
        if (callback) callback({ success: false, error: "Not supported" });
    }

    function disconnectEthernet(connectionName, callback) {
        if (callback) callback({ success: false, error: "Not supported" });
    }

    function disconnect(interfaceName, callback) {
        runCommand(["nmcli", "device", "disconnect", interfaceName || root.activeInterface], result => {
            refreshStatus();
            if (callback) callback(result.success ? result.output : "");
        });
    }

    // Details/Helpers stubs
    function getEthernetDeviceDetails(interfaceName, callback) {
        if (callback) callback(null);
    }

    function getWirelessDeviceDetails(interfaceName, callback) {
        if (callback) callback({
            interface: root.activeInterface,
            macAddress: "",
            driver: "NetworkManager"
        });
    }

    function getDeviceDetails(interfaceName, callback) {
        if (callback) callback("");
    }

    function getAllInterfaces(callback) {
        if (callback) callback([{ device: root.activeInterface, type: "wifi", state: root.isConnected ? "connected" : "disconnected", connection: root.activeConnection }]);
    }

    function isInterfaceConnected(interfaceName, callback) {
        if (callback) callback(root.isConnected);
    }

    function bringInterfaceUp(interfaceName, callback) {
        enableWifi(true, callback);
    }

    function bringInterfaceDown(interfaceName, callback) {
        enableWifi(false, callback);
    }

    // Parser Helpers
    function parseGetNetworks(output) {
        const lines = output.split('\n');
        const list = [];
        for (const line of lines) {
            if (!line.trim()) continue;
            const normalizedLine = line.replace(/\\:/g, '__COLON__');
            const parts = normalizedLine.split(':');
            if (parts.length < 5) continue;

            const active = parts[0].trim() === "yes" || parts[0].trim() === "*";
            const ssid = parts[1].replace(/__COLON__/g, ':').trim();
            const signalStr = parts[2].trim();
            const security = parts[3].replace(/__COLON__/g, ':').trim();
            const bssid = parts[4].replace(/__COLON__/g, ':').trim();

            if (!ssid) continue;

            const strength = parseInt(signalStr) || 0;
            const existingIdx = list.findIndex(n => n.ssid === ssid);
            if (existingIdx >= 0) {
                if (strength > list[existingIdx].strength) {
                    list[existingIdx].strength = strength;
                    list[existingIdx].active = list[existingIdx].active || active;
                }
            } else {
                list.push({
                    active: active,
                    strength: strength,
                    frequency: 2400,
                    ssid: ssid,
                    bssid: bssid,
                    security: security === "--" ? "" : security
                });
            }
        }
        return list;
    }

    function runCommand(args, callback) {
        const proc = procComponent.createObject(root, { cmdArgs: args, callback: callback });
        activeProcesses.push(proc);
        proc.processFinished.connect(() => {
            const idx = activeProcesses.indexOf(proc);
            if (idx >= 0) activeProcesses.splice(idx, 1);
        });
        proc.running = true;
    }

    Component {
        id: procComponent
        CommandProcess {}
    }

    Component {
        id: apComp
        AccessPoint {}
    }

    Component.onCompleted: {
        runCommand(["nmcli", "-t", "-f", "device,type", "device"], result => {
            if (result.success) {
                const lines = result.output.split('\n');
                for (const line of lines) {
                    const parts = line.trim().split(':');
                    if (parts.length >= 2 && parts[1] === "wifi") {
                        root.activeInterface = parts[0];
                        break;
                    }
                }
            }

            getWifiStatus();
            loadSavedConnections();
            refreshStatus();
            getNetworks();
        });
    }

    component CommandProcess: Process {
        id: proc
        property var callback: null
        property list<string> cmdArgs: []
        signal processFinished

        command: cmdArgs
        stdout: StdioCollector { id: outColl }
        stderr: StdioCollector { id: errColl }

        onExited: code => {
            const cleanOutput = outColl.text.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqrtuy=><]/g, '');
            const cleanError = errColl.text.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqrtuy=><]/g, '');
            if (callback) {
                callback({
                    success: code === 0,
                    output: cleanOutput,
                    error: cleanError,
                    exitCode: code
                });
            }
            processFinished();
            destroy();
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }
}
