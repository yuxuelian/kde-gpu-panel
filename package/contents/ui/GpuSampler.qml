import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Plasma5Support.DataSource {
    id: runner
    engine: "executable"
    property var cards: []
    property bool loading: true
    property bool failed: false
    readonly property string collector: decodeURIComponent(Qt.resolvedUrl("../code/gpus.py").toString().replace(/^file:\/\/\//, "/"))
    readonly property string command: "python3 '" + collector.split("'").join("'\\''") + "'"

    function refresh() {
        if (connectedSources.length === 0)
            connectSource(command)
    }

    onNewData: (source, data) => {
        disconnectSource(source)
        loading = false
        try {
            if (data["exit code"] !== 0)
                throw new Error("Collector exited with " + data["exit code"])
            const prior = cards
            const next = JSON.parse(data.stdout)
            for (const gpu of next) {
                if (!gpu.shared) continue
                const old = prior.find(card => card.id === gpu.id)
                if (!old || gpu.timestamp <= old.timestamp) continue
                let busy = 0
                let matched = false
                for (const id of Object.keys(gpu.engines)) {
                    if (old.engines[id] !== undefined && gpu.engines[id] >= old.engines[id]) {
                        busy += gpu.engines[id] - old.engines[id]
                        matched = true
                    }
                }
                if (matched)
                    gpu.metrics[0] = Math.min(100, Math.round(100 * busy / (gpu.timestamp - old.timestamp)))
            }
            cards = next
            failed = false
        } catch (error) {
            failed = true
            cards = []
            console.warn("GPU panel:", error)
        }
    }
}
