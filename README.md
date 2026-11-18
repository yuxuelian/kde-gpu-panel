# GPU 面板监视器（KDE Plasma 6）

右键点击横向面板 → 进入编辑模式 → 添加部件 → 搜索「GPU 面板监视器」，拖到面板上。每 2 秒刷新，按 PCI 地址顺序并排显示 `GPU0[核心使用率/已用显存/总显存]`。

依赖 Python 3。NVIDIA 数据来自 `nvidia-smi`；其他 GPU 从 DRM/sysfs 读取驱动公开的指标。缺失的指标显示 `—`。`M` 和 `G` 分别代表 MiB 和 GiB。

```sh
kpackagetool6 --type Plasma/Applet -i package  # 首次安装
kpackagetool6 --type Plasma/Applet -u package  # 更新
plasmawindowed local.gpupanelsummary          # 单独打开预览
kpackagetool6 --type Plasma/Applet -r local.gpupanelsummary  # 卸载
```
