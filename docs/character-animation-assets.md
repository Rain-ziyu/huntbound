# 戍边 角色骨骼与预览动画

打开 assets/models/hunter-forest-v1.tscn，选择 AnimationPreview，在动画面板播放 light、heavy、guard、fourfold 等片段。动画库为 resources/animations/trident_library.tres。

模型保存 Skeleton3D、Skin、带骨骼索引与权重的 ArrayMesh，以及前臂和手部父子层级。当前是分段刚性权重，每个顶点绑定一个骨骼，不是平滑连续的人体拓扑，也不代表角色概念图的最终建模完成。

17 个片段包括 idle、light、heavy、pull、turn、guard、reply、flash、throw、fourfold、spin、plant、wait、counter_window、finisher、dodge、hurt。片段由当前程序化姿态按 30 FPS 烘焙，供编辑器预览，不是已经完成的手工关键帧动画。

游戏仍由战斗时钟和握点求解驱动骨骼，预览播放器不自动接管战斗。wait 预览循环不决定 30 秒等待，免伤和伤害窗口不由预览动画决定。正式根运动、步态、平滑蒙皮、关键帧和运行时 AnimationTree 仍需制作。

在项目根目录依次执行可重建文件，现有模型与库会更新：

```powershell
& 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tools/bake_hunter_animations.gd
& 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tools/export_hunter_model.gd
& 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/test_skin.gd
```

修改武器、关节或姿态后需重新烘焙。技术接口参考：
https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html
https://docs.godotengine.org/en/stable/classes/class_skin.html
