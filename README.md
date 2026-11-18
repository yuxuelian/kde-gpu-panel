# GPU 面板监视器（KDE Plasma 6）

右键点击横向面板 → 进入编辑模式 → 添加部件 → 搜索「GPU 面板监视器」，拖到面板上。每 2 秒刷新，按 PCI 地址顺序并排显示 `GPU0[核心使用率/已用显存/总显存]`。

右键组件 → 配置 GPU 面板监视器 → GPU 显示，勾选要显示的设备，点击「应用」。默认显示全部 GPU，选择按设备地址保存，隐藏设备不会给其他 GPU 重新编号。

依赖 Python 3。NVIDIA 数据来自 `nvidia-smi`；Intel i915 核显通过普通用户可读的 DRM `fdinfo` 估算 Render/3D 使用率及驻留内存，第一轮采样没有使用率。以 `~` 标记估算：不可读或短命客户端可能被漏算，共享对象可能重复计入。核显总显存显示为 `共享`，不代表整机 RAM。其他 GPU 从 DRM/sysfs 读取驱动公开的指标。缺失的指标显示 `—`。`M` 和 `G` 分别代表 MiB 和 GiB。

```sh
kpackagetool6 --type Plasma/Applet -i package  # 首次安装
kpackagetool6 --type Plasma/Applet -u package  # 更新
plasmawindowed local.gpupanelsummary          # 单独打开预览
kpackagetool6 --type Plasma/Applet -r local.gpupanelsummary  # 卸载
```
