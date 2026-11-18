import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    property string summary: "GPU…"
    readonly property string collector: decodeURIComponent(Qt.resolvedUrl("../code/gpus.py").toString().replace(/^file:\/\/\//, "/"))
    readonly property string command: "python3 '" + collector.split("'").join("'\\''") + "'"
    preferredRepresentation: fullRepresentation
    toolTipMainText: "GPU 面板监视器"
    toolTipSubText: "核心使用率 / 已用显存 / 总显存；— 表示驱动未提供数据"

    function memory(mib) {
        if (mib === null) return "—"
        if (mib === 0) return "0M"
        if (mib < 1024) return Math.ceil(mib) + "M"
        return Number((mib / 1024).toFixed(1)) + "G"
    }

    function refresh() {
        if (runner.connectedSources.length === 0)
            runner.connectSource(root.command)
    }

    Plasma5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source, data) => {
            runner.disconnectSource(source)
            if (data["exit code"] !== 0) {
                root.summary = "GPU 读取失败"
                return
            }
            try {
                const cards = JSON.parse(data.stdout)
                root.summary = cards.map((card, index) => {
                    const m = card.metrics
                    return "GPU" + index + "[" + (m[0] === null ? "—" : m[0] + "%")
                        + "/" + root.memory(m[1]) + "/" + root.memory(m[2]) + "]"
                }).join("  ") || "未检测到 GPU"
            } catch (error) {
                root.summary = "GPU 读取失败"
                console.warn("GPU panel:", error)
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    fullRepresentation: PlasmaComponents.Label {
        text: root.summary
        textFormat: Text.PlainText
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.NoWrap
        Layout.minimumWidth: implicitWidth + 8
        Layout.preferredWidth: implicitWidth + 8
    }
}
