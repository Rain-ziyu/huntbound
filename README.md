# 戍边

戍边 是一个准备开发的 3D 合作狩猎游戏，目标是四人小队共同挑战大型怪物。正式名称为《戍边》，设计方向参考《怪物猎人：世界》的组队狩猎体验。

当前工程已有可运行的单机第三人称湿林战斗原型，包含三叉戟规则、五种巨兽初稿与弱点伤害判定。人物、巨兽、地形和动作仍为程序化初稿，不是最终建模与动画；难度、连携手感和完整特性尚未验收，四人联机尚未实现。

## 打开项目

1. 使用 Godot 4.7.2 标准版，在项目管理器中导入根目录的 `project.godot`。
2. 打开工程后按 F5，进入湿林战斗原型。角色前方是苔甲龙，其他四种巨兽分布在林地两侧。
3. 当前使用 GDScript 工程基础和 Compatibility 渲染，无需 .NET。

已安装的本机引擎可用 PowerShell 启动，命令在项目根目录执行：

```powershell
& 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' --editor --path .
```

## 开发目标

- 3D 第三人称动作体验。
- 四人小队协作狩猎大型怪物；暂按队伍总人数为四人理解。
- 围绕怪物招式观察、躲避、攻击时机与队友配合建立战斗循环。
- 逐步形成任务准备、出发狩猎、任务结算与装备成长的循环。

具体武器、战斗手感、联机服务与美术风格需要在实现前讨论确认。以上是目标方向，不代表已完成功能。

## 目录

- `scenes/main`：启动场景。
- `scenes/players`、`scenes/monsters`、`scenes/levels`、`scenes/ui`：后续游戏场景。
- `scripts/player`、`scripts/combat`、`scripts/monster`、`scripts/network`：后续功能代码。
- `assets/models`、`assets/textures`、`assets/audio`：游戏素材。
- `resources`：后续武器、怪物和任务数据。
- `docs`：项目方向和开发路线。
- `tests`：后续行为与联机测试。
- `builds`：本地导出产物，不提交到 Git。

## 版本管理

主分支为 `main`。提交 Godot 场景、脚本、源素材和 `.uid` 文件，忽略 `.godot` 缓存。
模型及部分音频格式已配置 Git LFS，协作者克隆前应安装 Git LFS。
仓库中不保存本机 MCP 配置、访问令牌或商业游戏素材。

参考作品仅用于讨论玩法体验，角色、怪物、地图、音乐与其他资产采用原创或取得授权的素材。

## 下一步

当前实现范围、测试结果与未完成目标见 [战斗实现进度](docs/combat-implementation-status.md)。初始方向见 [项目方向](docs/game-direction.md)。

## 原型操作

WASD 移动，鼠标转视角，Shift 奔跑，空格闪避，中键锁定，Esc 释放鼠标，F5 重试。

左键轻击；右键短按横扫，长按后松开投掷位移；E 回拉；Alt 加左键转身；Q 格挡。成功格挡后左键反击，反击命中后 Ctrl 加左键闪刺以获得枪影。

刺击会随鼠标仰视或俯视抬高、压低枪尖；攻击高处雾囊或背棘时需要调整视角和站位。近战按有效帧中的实际枪头、枪尾或脚部轨迹检测，不再一次结算整个扇形。

有枪影时 Ctrl 加左键四连刺、Ctrl 加右键旋转；每次消耗一层。拔枪时 Ctrl 加空格插地，再单按 Ctrl 开启 0.5 秒反击窗口。R 收枪。

## 验证

在项目根目录执行：

```powershell
& 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/test_combat.gd
& 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/test_world.gd
```

规则检查和场景集成检查不代表实际操作手感、美术、碰撞精度或完整对战已经验收。
