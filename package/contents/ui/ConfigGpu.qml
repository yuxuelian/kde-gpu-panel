import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property string cfg_hiddenGpuIds: ""
    property string cfg_hiddenGpuIdsDefault: ""

    GpuSampler {
        id: sampler
        Component.onCompleted: refresh()
    }

    Controls.Label {
        Kirigami.FormData.label: "显示设备："
        text: sampler.loading ? "正在检测 GPU…" : sampler.failed ? "读取 GPU 失败" :
              sampler.cards.length === 0 ? "未检测到 GPU" : "勾选要在面板上显示的 GPU"
    }

    ColumnLayout {
        Repeater {
            model: sampler.cards
            Controls.CheckBox {
                required property var modelData
                required property int index
                text: "GPU" + index + " — " + modelData.id + (modelData.shared ? "（Intel 核显）" : "")
                checked: !page.cfg_hiddenGpuIds.split(",").includes(modelData.id)
                onToggled: {
                    const hidden = page.cfg_hiddenGpuIds.split(",").filter(id => id && id !== modelData.id)
                    if (!checked) hidden.push(modelData.id)
                    page.cfg_hiddenGpuIds = hidden.join(",")
                }
            }
        }
    }
}
