# 戍边

戍边 是一个准备开发的 3D 合作狩猎游戏，目标是四人小队共同挑战大型怪物。正式名称为《戍边》，设计方向参考《怪物猎人：世界》的组队狩猎体验。

当前仓库完成了项目初始化，可运行启动场景。四人联机、角色战斗、怪物 AI、装备成长均尚未实现。

## 打开项目

1. 使用 Godot 4.7.2 标准版，在项目管理器中导入根目录的 `project.godot`。
2. 打开工程后按 F5，显示项目标题与基础 3D 地面。
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

先阅读 [项目方向](docs/game-direction.md) 与 [开发路线](docs/roadmap.md)，确认第一阶段设计后再开始制作可玩的战斗原型。
