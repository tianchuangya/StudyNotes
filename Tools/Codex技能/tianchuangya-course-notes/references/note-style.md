# Markdown 笔记样式

## 推荐骨架

按内容取舍小节，不为套模板制造空白章节。

```markdown
# 第 X 章 · 标题

## 本章知识地图

## 1. 模块名称

### 1.1 知识点

- 定义
- 原理 / 过程
- 作用
- 最小示例
- 易错与易混

## 对比速查

## 查漏补缺

## 本章速记 / 自测
```

## 四色语义

只给关键词、短语和标签着色，不给标题、整段正文、代码块或公式着色。每个句子通常只突出一个重点，同一短语不得叠色。

| 语义 | 样式 | 用法 |
| --- | --- | --- |
| 淡紫色 | `<span style="background:#f3e8ff;color:#6b21a8;padding:2px 6px;border-radius:4px;">文本</span>` | 同类、并列概念或名称 |
| 淡青色 | `<span style="background:#ccfbf1;color:#155e75;padding:2px 6px;border-radius:4px;">文本</span>` | 专有名词、定义中的术语主语 |
| 淡红色 | `<span style="background:#fee2e2;color:#991b1b;padding:2px 6px;border-radius:4px;">文本</span>` | 核心结论、限制条件、纠错、易错或易混 |
| 淡绿色 | `<span style="background:#dcfce7;color:#166534;padding:2px 6px;border-radius:4px;">文本</span>` | 解释、原因、作用或补充说明 |

颜色只是辅助信息。必须同时保留“定义”“作用”“纠错”“易错”等文字线索，使不支持内联 HTML 的阅读器仍能表达完整语义。

## 图示使用

- 用户明确要“图片、图示、流程图、动态演示”时，输出必须包含真实可渲染图示：优先 Mermaid 或 SVG；需要像素风格、照片感或复杂插画时再生成图片。
- 不要用 `A ↓ B ↓ C`、ASCII 框图或大段文字说明来冒充图片。它们最多作为图旁边的短注释或代码映射说明。
- 图示应有标题、少量节点、清晰方向和必要标签；图内文字保持短句，详细解释放在图下方。
- 对“编号拆解、层级映射、函数参数流向、封装/解封装、状态变化”等内容，优先画成流程图或分层图。

## 最小写法示例

```markdown
### 进程与程序

<span style="background:#ccfbf1;color:#155e75;padding:2px 6px;border-radius:4px;">进程（process）</span>：程序的一次动态执行实例。

| 概念 | 性质 | 是否占用运行资源 |
| --- | --- | --- |
| <span style="background:#f3e8ff;color:#6b21a8;padding:2px 6px;border-radius:4px;">程序</span> | 静态代码与数据 | 否 |
| <span style="background:#f3e8ff;color:#6b21a8;padding:2px 6px;border-radius:4px;">进程</span> | 动态执行活动 | 是 |

<span style="background:#fee2e2;color:#991b1b;padding:2px 6px;border-radius:4px;">易错</span>：程序不等于进程；同一程序可以对应多个进程。

<span style="background:#dcfce7;color:#166534;padding:2px 6px;border-radius:4px;">作用</span>：进程是操作系统分配和管理运行资源的基本抽象之一。
```

## 交付检查

- 原稿每个有效关键词都已保留、纠正或明确排除。
- 定义与例子属于同一抽象层次，不把设备、程序、协议或数据单元混为一谈。
- “可能、通常、不保证”没有被改写成绝对结论。
- 表格适合比较，流程图适合关系，代码适合行为；视觉形式与知识关系匹配。
- 彩色标记稀疏且语义一致，相对资源链接有效。
