# discourse-moaclab-typing

moaclab.com 的打字练习主题组件，页面在 `/typing`。路由由服务端插件 `discourse-moaclab-tools` 注册，本组件只负责前端。

站点级的发布流程、线上组件 ID 和发布记录在私有维护仓库 `mohist-club/Moaclab`（`components/typing.md`、`ops/release.md`）。本文件只写这个仓库内的开发约定。

## 目录

| 路径 | 内容 |
| --- | --- |
| `javascripts/discourse/api-initializers/moaclab-typing.gjs` | 组件主体 |
| `javascripts/discourse/lib/moaclab-typing-layout.js` | 布局计算 |
| `javascripts/discourse/lib/moaclab-typing-words.js` | 词库，生成文件 |
| `common/common.scss` | 样式 |
| `locales/` | `en` 与 `zh_CN` 文案 |
| `settings.yml` | 组件设置 |
| `scripts/` | 词库生成、预览构建、检查脚本 |

## 约定

- **词库是生成文件**：`moaclab-typing-words.js` 由 `scripts/build-hsk-wordlist.mjs` 生成，不手改。词库来源和许可见 `THIRD_PARTY_NOTICES.md`。
- **文案**：界面文字全部放在 `locales/`，用 `themePrefix` 读取，`en` 与 `zh_CN` 同步更新。
- **动效**：新增动效要跟随对应的效果开关，并在系统开启"减少动态效果"时关闭。
- **离线**：运行时不请求第三方接口，不引入外部 CDN 资源。
- **样式**：颜色用 Discourse 的 CSS 变量，保证浅色和深色主题都可用。
- 不新增依赖，确有需要先问。

## 检查

使用 Node.js 22：

```sh
npm ci
npm test
```

`npm test` 检查元数据、词库、SCSS 编译和 JavaScript 打包。它不能代替在真实 Discourse 上的验证，界面改动要按维护仓库的流程在站点上实测桌面和手机宽度。

## 版本与发布

1. 从 `main` 开分支，一个分支只做一件事。
2. 同步更新三处版本：`about.json` 的 `theme_version`、`package.json`（及 `package-lock.json`）的 `version`、`README.md` 顶部的更新记录。
3. 推分支，开指向 `main` 的 PR，等 Actions 通过。合并由仓库所有者完成，合并后删除分支。
4. 合并后打 `vX.Y.Z` tag。
5. 更新到网站按维护仓库的 `ops/release.md` 执行，并在 `components/typing.md` 的发布记录里追加一行。

## 不要做

- 不直接推 `main`，不强制推送。
- 不提交密钥或站点数据。
- 更新线上组件属于生产操作，需要仓库所有者在当前对话里明确批准。
- 不做任务范围以外的重构。
