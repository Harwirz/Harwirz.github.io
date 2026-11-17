# 搞搞新意思

Harwirz 的 Jekyll 个人博客。以文章为中心的简洁个人网站，兼容现有 GitHub Pages 构建。

## 本地预览

在 Ubuntu 终端中运行：

```sh
cd ~/projects/Harwirz.github.io
bundle exec jekyll serve --host 127.0.0.1
```

然后访问 http://localhost:4000 。停止预览按 `Ctrl+C`。正式检查可运行 `bundle exec jekyll build`。

## 写文章

在 `_posts/` 新建 `YYYY-MM-DD-slug.md`：

```md
---
layout: post
title: "文章标题"
date: 2026-11-17 12:00:00 +0800
categories: [笔记]
tags: [阅读, 学习记录]
---

这一段会作为首页的文章开头。
<!--more-->

## 正文

从这里继续写。
```

类别和标签可自行添加，顶部索引、年份及完整归档会自动更新。`_config.yml` 的 `category_order` 控制优先展示的类别；其中没有文章的类别仍保留索引。其他实际使用的类别自动追加。日期在未来的文章遵循 Jekyll 默认设置，到日期后重新构建才会显示。

## 首页缩略图

默认取正文第一张图片，支持 Markdown 图片（包括引用式写法）和 HTML 图片。图片完整按比例显示在标题下方左侧，无图时不留占位。

要指定某张图片，在文章开头的 front matter 中添加：

```yaml
thumbnail: /assets/images/文章配图.jpg
thumbnail_alt: "图片说明"
```

`thumbnail` 优先于正文首图；不需要缩略图时写 `thumbnail: false`。本地图片建议放在 `assets/images/` 并使用以 `/` 开头的站内路径。也可使用完整的图片网址。正文内的相对图片路径会按文章网址所在目录解析。

## 修改个人资料与样式

- `_config.yml`：网站标题、欢迎语、头像路径、GitHub 地址、类别顺序。
- `about.md`：个人简介。
- `assets/images/avatar.jpg`：本地头像，当前取自 GitHub 公开头像。
- `assets/main.scss`：颜色、字体、版式和手机断点。
- `_layouts/`：首页、文章、页面、归档的 Liquid 模板。
- `assets/archive.js`：首页的类别 / 年份 / 标签筛选与时间排序。

筛选条件会写入地址栏，支持分享、刷新和浏览器前进后退。关闭 JavaScript 时，索引链接进入 `/archive/` 对应分组。文章、个人资料和 RSS 都是静态内容，不依赖 JavaScript。

详细设计说明见 `DESIGN_NOTES.md`。
