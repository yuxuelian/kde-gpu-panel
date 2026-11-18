import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    toolTipMainText: "GPU 面板监视器"
    toolTipSubText: "核心使用率 / 已用显存 / 总显存；~ 为可见客户端估算，— 为无数据"
    readonly property string summary: {
        if (sampler.loading) return "GPU…"
        if (sampler.failed) return "GPU 读取失败"
        if (sampler.cards.length === 0) return "未检测到 GPU"
        const hidden = Plasmoid.configuration.hiddenGpuIds.split(",")
        return sampler.cards.map((gpu, index) => {
            if (hidden.includes(gpu.id)) return ""
            const m = gpu.metrics
            const prefix = gpu.shared ? "~" : ""
            return "GPU" + index + "[" + (m[0] === null ? "—" : prefix + m[0] + "%")
                + "/" + (m[1] === null ? "—" : prefix + root.memory(m[1]))
                + "/" + (gpu.shared ? "共享" : root.memory(m[2])) + "]"
        }).filter(text => text !== "").join("  ") || "GPU 已隐藏"
    }

    function memory(mib) {
        if (mib === null) return "—"
        if (mib === 0) return "0M"
        if (mib < 1024) return Math.ceil(mib) + "M"
        return Number((mib / 1024).toFixed(1)) + "G"
    }

    GpuSampler { id: sampler }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sampler.refresh()
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
