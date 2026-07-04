pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: NetworkManager.scanning
    property list<var> ethernetDevices: []
    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    property int ethernetDeviceCount: 0
    property bool ethernetProcessRunning: false
    property var ethernetDeviceDetails: null
    property var wirelessDeviceDetails: null
    property var pendingConnection: null
    property list<string> savedConnections: []
    property list<string> savedConnectionSsids: []

    signal connectionFailed(string ssid)

    function enableWifi(enabled: bool): void {
        NetworkManager.enableWifi(enabled, result => {
            if (result.success) {
                root.getWifiStatus();
                NetworkManager.getNetworks(() => {
                    syncNetworksFromNetworkManager();
                });
            }
        });
    }

    function toggleWifi(): void {
        NetworkManager.toggleWifi(result => {
            if (result.success) {
                root.getWifiStatus();
                NetworkManager.getNetworks(() => {
                    syncNetworksFromNetworkManager();
                });
            }
        });
    }

    function rescanWifi(): void {
        NetworkManager.rescanWifi();
    }

    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        // Set up pending connection tracking if callback provided
        if (callback) {
            const hasBssid = bssid !== undefined && bssid !== null && bssid.length > 0;
            root.pendingConnection = {
                ssid: ssid,
                bssid: hasBssid ? bssid : "",
                callback: callback
            };
        }

        NetworkManager.connectToNetwork(ssid, password, bssid, result => {
            if (result && result.success) {
                // Connection successful
                if (callback)
                    callback(result);
                root.pendingConnection = null;
            } else if (result && result.needsPassword) {
                // Password needed - callback will handle showing dialog
                if (callback)
                    callback(result);
            } else {
                // Connection failed
                if (result && result.error) {
                    root.connectionFailed(ssid);
                }
                if (callback)
                    callback(result);
                root.pendingConnection = null;
            }
        });
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        // Set up pending connection tracking
        const hasBssid = bssid !== undefined && bssid !== null && bssid.length > 0;
        root.pendingConnection = {
            ssid: ssid,
            bssid: hasBssid ? bssid : "",
            callback: callback
        };

        NetworkManager.connectToNetworkWithPasswordCheck(ssid, isSecure, result => {
            if (result && result.success) {
                // Connection successful
                if (callback)
                    callback(result);
                root.pendingConnection = null;
            } else if (result && result.needsPassword) {
                // Password needed - callback will handle showing dialog
                if (callback)
                    callback(result);
            } else {
                // Connection failed
                if (result && result.error) {
                    root.connectionFailed(ssid);
                }
                if (callback)
                    callback(result);
                root.pendingConnection = null;
            }
        }, bssid);
    }

    function disconnectFromNetwork(): void {
        // Try to disconnect - use connection name if available, otherwise use device
        NetworkManager.disconnectFromNetwork();
        // Refresh network list after disconnection
        Qt.callLater(() => {
            NetworkManager.getNetworks(() => {
                syncNetworksFromNetworkManager();
            });
        }, 500);
    }

    function forgetNetwork(ssid: string): void {
        // Delete the connection profile for this network
        // This will remove the saved password and connection settings
        NetworkManager.forgetNetwork(ssid, result => {
            if (result.success) {
                // Refresh network list after deletion
                Qt.callLater(() => {
                    NetworkManager.getNetworks(() => {
                        syncNetworksFromNetworkManager();
                    });
                }, 500);
            }
        });
    }

    function syncNetworksFromNetworkManager(): void {
        const rNetworks = root.networks;
        const nNetworks = NetworkManager.networks;

        // Build a map of existing networks by key
        const existingMap = new Map();
        for (const rn of rNetworks) {
            const key = `${rn.frequency}:${rn.ssid}:${rn.bssid}`;
            existingMap.set(key, rn);
        }

        // Build a map of new networks by key
        const newMap = new Map();
        for (const nn of nNetworks) {
            const key = `${nn.frequency}:${nn.ssid}:${nn.bssid}`;
            newMap.set(key, nn);
        }

        // Remove networks that no longer exist
        for (const [key, network] of existingMap) {
            if (!newMap.has(key)) {
                const index = rNetworks.indexOf(network);
                if (index >= 0) {
                    rNetworks.splice(index, 1);
                    network.destroy();
                }
            }
        }

        // Add or update networks from NetworkManager
        for (const [key, nNetwork] of newMap) {
            const existing = existingMap.get(key);
            if (existing) {
                // Update existing network's lastIpcObject
                existing.lastIpcObject = nNetwork.lastIpcObject;
            } else {
                // Create new AccessPoint from NetworkManager's data
                rNetworks.push(apComp.createObject(root, {
                    lastIpcObject: nNetwork.lastIpcObject
                }));
            }
        }
    }

    function hasSavedProfile(ssid: string): bool {
        // Use NetworkManager's hasSavedProfile which has the same logic
        return NetworkManager.hasSavedProfile(ssid);
    }

    function getWifiStatus(): void {
        NetworkManager.getWifiStatus(enabled => {
            root.wifiEnabled = enabled;
        });
    }

    function getEthernetDevices(): void {
        root.ethernetProcessRunning = true;
        NetworkManager.getEthernetInterfaces(interfaces => {
            root.ethernetDevices = NetworkManager.ethernetDevices;
            root.ethernetDeviceCount = NetworkManager.ethernetDevices.length;
            root.ethernetProcessRunning = false;
        });
    }

    function connectEthernet(connectionName: string, interfaceName: string): void {
        NetworkManager.connectEthernet(connectionName, interfaceName, result => {
            if (result.success) {
                getEthernetDevices();
                // Refresh device details after connection
                Qt.callLater(() => {
                    const activeDevice = root.ethernetDevices.find(function (d) {
                        return d.connected;
                    });
                    if (activeDevice && activeDevice.interface) {
                        updateEthernetDeviceDetails(activeDevice.interface);
                    }
                }, 1000);
            }
        });
    }

    function disconnectEthernet(connectionName: string): void {
        NetworkManager.disconnectEthernet(connectionName, result => {
            if (result.success) {
                getEthernetDevices();
                // Clear device details after disconnection
                Qt.callLater(() => {
                    root.ethernetDeviceDetails = null;
                });
            }
        });
    }

    function updateEthernetDeviceDetails(interfaceName: string): void {
        NetworkManager.getEthernetDeviceDetails(interfaceName, details => {
            root.ethernetDeviceDetails = details;
        });
    }

    function updateWirelessDeviceDetails(): void {
        // Find the wireless interface by looking for wifi devices
        // Pass empty string to let NetworkManager find the active interface automatically
        NetworkManager.getWirelessDeviceDetails("", details => {
            root.wirelessDeviceDetails = details;
        });
    }

    function cidrToSubnetMask(cidr: string): string {
        // Convert CIDR notation (e.g., "24") to subnet mask (e.g., "255.255.255.0")
        const cidrNum = parseInt(cidr);
        if (isNaN(cidrNum) || cidrNum < 0 || cidrNum > 32) {
            return "";
        }

        const mask = (0xffffffff << (32 - cidrNum)) >>> 0;
        const octets = [(mask >>> 24) & 0xff, (mask >>> 16) & 0xff, (mask >>> 8) & 0xff, mask & 0xff];

        return octets.join(".");
    }

    Component.onCompleted: {
        // Trigger ethernet device detection after initialization
        Qt.callLater(() => {
            getEthernetDevices();
        });
        // Load saved connections on startup
        NetworkManager.loadSavedConnections(() => {
            root.savedConnections = NetworkManager.savedConnections;
            root.savedConnectionSsids = NetworkManager.savedConnectionSsids;
        });
        // Get initial WiFi status
        NetworkManager.getWifiStatus(enabled => {
            root.wifiEnabled = enabled;
        });
        // Sync networks from NetworkManager on startup
        Qt.callLater(() => {
            syncNetworksFromNetworkManager();
        }, 100);
    }

    // Sync saved connections and list from NetworkManager when they're updated
    Connections {
        function onSavedConnectionsChanged() {
            root.savedConnections = NetworkManager.savedConnections;
        }

        function onSavedConnectionSsidsChanged() {
            root.savedConnectionSsids = NetworkManager.savedConnectionSsids;
        }

        function onNetworksUpdated() {
            syncNetworksFromNetworkManager();
        }

        target: NetworkManager
    }

    Timer {
        id: monitorDebounce

        interval: 200
        onTriggered: {
            NetworkManager.getNetworks(() => {
                syncNetworksFromNetworkManager();
            });
            getEthernetDevices();
        }
    }

    Process {
        running: false
    }

    Component {
        id: apComp

        AccessPoint {}
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
