function localizedLearningText(app, values) {
  // Resolve localized learning copy with zh-CN fallback.
  // 使用 zh-CN 兜底解析学习模块文案。
  if (!values || typeof values !== 'object') {
    return '';
  }
  const locale = app?.locale || 'zh-CN';
  return values[locale] || values['zh-CN'] || values['en-US'] || '';
}

function escapeLearningHtml(value) {
  // Escape raw HTML before markdown rendering.
  // 在 Markdown 渲染前转义原始 HTML。
  return String(value ?? '').replace(/[&<>"']/g, (char) => {
    switch (char) {
      case '&':
        return '&amp;';
      case '<':
        return '&lt;';
      case '>':
        return '&gt;';
      case '"':
        return '&quot;';
      case "'":
        return '&#39;';
      default:
        return char;
    }
  });
}

function escapeLearningAttribute(value) {
  // Escape attribute values before embedding them into generated HTML.
  // 在生成 HTML 时转义属性值。
  return escapeLearningHtml(value).replace(/`/g, '&#96;');
}

async function copyLearningText(value) {
  // Copy text into the clipboard with a legacy fallback for older browsers.
  // 将文本复制到剪贴板，并为旧浏览器保留回退方案。
  const text = String(value || '');
  if (!text) {
    return;
  }
  if (navigator?.clipboard?.writeText) {
    await navigator.clipboard.writeText(text);
    return;
  }
  const textarea = document.createElement('textarea');
  textarea.value = text;
  textarea.setAttribute('readonly', 'readonly');
  textarea.style.position = 'fixed';
  textarea.style.opacity = '0';
  document.body.appendChild(textarea);
  textarea.select();
  document.execCommand('copy');
  document.body.removeChild(textarea);
}

function sanitizeLearningUrl(value) {
  // Keep only safe anchor targets inside learning markdown.
  // 仅保留学习 Markdown 中安全的链接目标。
  const raw = String(value || '').trim();
  if (!raw) {
    return '';
  }
  try {
    const parsed = new URL(raw, window.location.href);
    const protocol = parsed.protocol.toLowerCase();
    if (
      protocol === 'http:' ||
      protocol === 'https:' ||
      protocol === 'mailto:' ||
      protocol === 'tel:'
    ) {
      return parsed.href;
    }
  } catch (_error) {
    if (raw.startsWith('/') && !raw.startsWith('//')) {
      return raw;
    }
  }
  return '';
}

function renderLearningMarkdownInline(value) {
  // Render lightweight inline markdown for the course body.
  // 为课程正文渲染轻量级行内 Markdown。
  let text = escapeLearningHtml(value);
  const codeTokens = [];
  text = text.replace(/`([^`\n]+)`/g, (_, code) => {
    codeTokens.push(`<code>${code}</code>`);
    return `\u0000${codeTokens.length - 1}\u0000`;
  });

  const linkTokens = [];
  text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, label, url) => {
    const safeUrl = sanitizeLearningUrl(url);
    if (!safeUrl) {
      return escapeLearningHtml(label);
    }
    linkTokens.push(
      `<a href="${escapeLearningHtml(safeUrl)}" target="_blank" rel="noopener noreferrer">${escapeLearningHtml(label)}</a>`,
    );
    return `\u0001${linkTokens.length - 1}\u0001`;
  });

  text = text.replace(/(\*\*|__)(.+?)\1/g, '<strong>$2</strong>');
  text = text.replace(/(^|[^*])\*([^*\n]+)\*(?!\*)/g, '$1<em>$2</em>');
  text = text.replace(/\u0000(\d+)\u0000/g, (_, index) => codeTokens[Number(index)] || '');
  text = text.replace(/\u0001(\d+)\u0001/g, (_, index) => linkTokens[Number(index)] || '');
  return text;
}

function splitLearningTableRow(line) {
  // Split one markdown table row into trimmed cells.
  // 将一行 Markdown 表格拆分为去空白后的单元格。
  return String(line || '')
    .trim()
    .replace(/^\|/, '')
    .replace(/\|$/, '')
    .split('|')
    .map((cell) => cell.trim());
}

function isLearningTableSeparator(line) {
  // Detect the markdown separator row between table head and body.
  // 识别表头和表体之间的 Markdown 分隔线。
  const cells = splitLearningTableRow(line);
  if (!cells.length) {
    return false;
  }
  return cells.every((cell) => /^:?-{3,}:?$/.test(cell));
}

function parseLearningMarkdownBlocks(content) {
  // Parse the course body into block-level markdown tokens.
  // 将课程正文解析成块级 Markdown 令牌。
  const lines = String(content || '').replace(/\r\n?/g, '\n').split('\n');
  const blocks = [];
  const paragraphLines = [];
  let fence = null;
  let codeLines = [];

  const flushParagraph = () => {
    if (!paragraphLines.length) {
      return;
    }
    blocks.push({
      type: 'paragraph',
      text: paragraphLines.join('\n'),
    });
    paragraphLines.length = 0;
  };

  for (let index = 0; index < lines.length;) {
    const line = lines[index];
    const trimmed = line.trim();

    if (fence) {
      if (trimmed.startsWith(fence.delimiter)) {
        blocks.push({
          type: fence.info === 'mermaid' ? 'mermaid' : 'code',
          info: fence.info,
          text: codeLines.join('\n'),
        });
        fence = null;
        codeLines = [];
      } else {
        codeLines.push(line);
      }
      index += 1;
      continue;
    }

    if (!trimmed) {
      flushParagraph();
      index += 1;
      continue;
    }

    const headingMatch = trimmed.match(/^(#{1,6})\s+(.*)$/);
    if (headingMatch) {
      flushParagraph();
      blocks.push({
        type: 'heading',
        level: headingMatch[1].length,
        text: headingMatch[2] || '',
      });
      index += 1;
      continue;
    }

    const fenceMatch = trimmed.match(/^(```|~~~)\s*([\w-]+)?\s*$/);
    if (fenceMatch) {
      flushParagraph();
      fence = {
        delimiter: fenceMatch[1],
        info: String(fenceMatch[2] || '').toLowerCase(),
      };
      codeLines = [];
      index += 1;
      continue;
    }

    if (/^([-*_])(?:\s*\1){2,}\s*$/.test(trimmed)) {
      flushParagraph();
      blocks.push({ type: 'thematicBreak' });
      index += 1;
      continue;
    }

    if (
      index + 1 < lines.length &&
      line.includes('|') &&
      lines[index + 1].includes('|') &&
      isLearningTableSeparator(lines[index + 1])
    ) {
      flushParagraph();
      const header = splitLearningTableRow(line);
      const rows = [];
      index += 2;
      while (index < lines.length) {
        const current = lines[index];
        if (!current.trim() || !current.includes('|')) {
          break;
        }
        rows.push(splitLearningTableRow(current));
        index += 1;
      }
      blocks.push({
        type: 'table',
        header,
        rows,
      });
      continue;
    }

    if (trimmed.startsWith('>')) {
      flushParagraph();
      const quoteLines = [];
      while (index < lines.length) {
        const quoteTrimmed = lines[index].trim();
        if (!quoteTrimmed.startsWith('>')) {
          break;
        }
        quoteLines.push(quoteTrimmed.replace(/^>\s?/, ''));
        index += 1;
      }
      blocks.push({
        type: 'quote',
        text: quoteLines.join('\n'),
      });
      continue;
    }

    const unorderedMatch = trimmed.match(/^[-*+]\s+(.+)$/);
    if (unorderedMatch) {
      flushParagraph();
      const items = [];
      while (index < lines.length) {
        const current = lines[index].trim().match(/^[-*+]\s+(.+)$/);
        if (!current) {
          break;
        }
        const taskMatch = current[1].match(/^\[( |x|X)\]\s+(.+)$/);
        items.push({
          text: taskMatch ? taskMatch[2] : current[1],
          checked: taskMatch ? taskMatch[1].toLowerCase() === 'x' : null,
        });
        index += 1;
      }
      blocks.push({
        type: 'unorderedList',
        items,
      });
      continue;
    }

    const orderedMatch = trimmed.match(/^\d+\.\s+(.+)$/);
    if (orderedMatch) {
      flushParagraph();
      const items = [];
      while (index < lines.length) {
        const current = lines[index].trim().match(/^\d+\.\s+(.+)$/);
        if (!current) {
          break;
        }
        items.push(current[1] || '');
        index += 1;
      }
      blocks.push({
        type: 'orderedList',
        items,
      });
      continue;
    }

    paragraphLines.push(line);
    index += 1;
  }

  flushParagraph();
  if (fence) {
    blocks.push({
      type: fence.info === 'mermaid' ? 'mermaid' : 'code',
      info: fence.info,
      text: codeLines.join('\n'),
    });
  }
  return blocks;
}

function renderLearningMarkdownContent(content, options = {}) {
  // Convert course markdown into safe HTML for the learning view.
  // 将课程 Markdown 转换为学习页可用的安全 HTML。
  return parseLearningMarkdownBlocks(content)
    .map((block, blockIndex) => {
      switch (block.type) {
        case 'heading':
          return `<h${block.level}>${renderLearningMarkdownInline(block.text)}</h${block.level}>`;
        case 'quote':
          return `<blockquote><p>${renderLearningMarkdownInline(block.text).replace(/\n/g, '<br>')}</p></blockquote>`;
        case 'thematicBreak':
          return '<hr />';
        case 'code': {
          const isRunnable = typeof options.isRunnableCode === 'function'
            ? Boolean(options.isRunnableCode(block, blockIndex))
            : false;
          const executionState = typeof options.executionState === 'function'
            ? options.executionState(block, blockIndex) || null
            : null;
          const runLabels = options.labels || {};
          const languageBadge = block.info
            ? `<div class="learning-code-head"><span class="learning-code-badge">${escapeLearningHtml(block.info)}</span></div>`
            : '';
          const runnableActions = isRunnable
            ? `
              <div class="learning-code-head">
                <span class="learning-code-badge">${escapeLearningHtml(block.info || 'go')}</span>
                <div class="learning-code-actions">
                  <button
                    type="button"
                    class="ghost compact learning-copy-button"
                    data-learning-copy-code="true"
                    data-learning-block-index="${blockIndex}"
                  >${escapeLearningHtml(runLabels.copy || 'Copy code')}</button>
                  <button
                    type="button"
                    class="tonal compact learning-run-button"
                    data-learning-run="code"
                    data-learning-block-index="${blockIndex}"
                    ${executionState?.running ? 'disabled' : ''}
                  >${escapeLearningHtml(executionState?.running ? (runLabels.running || 'Running...') : (runLabels.run || 'Run'))}</button>
                </div>
              </div>
            `
            : languageBadge;
          const outputShell = isRunnable && executionState
            ? `
              <div class="learning-run-result">
                <div class="learning-run-result-head">
                  <span class="learning-run-result-badge">${escapeLearningHtml(executionState.error ? (runLabels.error || 'Request error') : (runLabels.output || 'Output'))}</span>
                  <div class="learning-run-result-actions">
                    <span class="learning-run-result-meta">${escapeLearningHtml(executionState.meta || '')}</span>
                    <button
                      type="button"
                      class="ghost compact learning-reset-button"
                      data-learning-reset-output="true"
                      data-learning-block-index="${blockIndex}"
                    >${escapeLearningHtml(runLabels.reset || 'Reset output')}</button>
                  </div>
                </div>
                ${executionState.error
                  ? `<pre class="learning-run-result-body learning-run-result-body--error"><code>${escapeLearningHtml(executionState.error)}</code></pre>`
                  : `
                    ${executionState.stdout
                      ? `<pre class="learning-run-result-body"><code>${escapeLearningHtml(executionState.stdout)}</code></pre>`
                      : `<div class="learning-run-result-empty">${escapeLearningHtml(runLabels.empty || 'No stdout output.')}</div>`}
                    ${executionState.stderr
                      ? `
                        <div class="learning-run-result-head learning-run-result-head--stderr">
                          <span class="learning-run-result-badge learning-run-result-badge--stderr">${escapeLearningHtml(runLabels.stderr || 'stderr')}</span>
                        </div>
                        <pre class="learning-run-result-body learning-run-result-body--error"><code>${escapeLearningHtml(executionState.stderr)}</code></pre>
                      `
                      : ''}
                  `}
              </div>
            `
            : '';
          return `<div class="learning-code-shell">${runnableActions}<pre><code>${escapeLearningHtml(block.text)}</code></pre>${outputShell}</div>`;
        }
        case 'mermaid':
          return `
            <div class="learning-mermaid-shell">
              <div class="learning-code-head">
                <span class="learning-code-badge">mermaid</span>
                <span class="learning-mermaid-hint">Mind map / 思维导图</span>
              </div>
              <pre class="learning-mermaid-graph mermaid">${escapeLearningHtml(block.text)}</pre>
            </div>
          `;
        case 'unorderedList':
          return `<ul>${(block.items || []).map((item) => {
            const prefix = item.checked === null
              ? ''
              : `<span class="learning-task-chip">${item.checked ? '✓' : '○'}</span>`;
            return `<li>${prefix}${renderLearningMarkdownInline(item.text || '')}</li>`;
          }).join('')}</ul>`;
        case 'orderedList':
          return `<ol>${(block.items || []).map((item) => `<li>${renderLearningMarkdownInline(item)}</li>`).join('')}</ol>`;
        case 'table':
          return `
            <div class="learning-table-shell">
              <table>
                <thead>
                  <tr>${(block.header || []).map((cell) => `<th>${renderLearningMarkdownInline(cell)}</th>`).join('')}</tr>
                </thead>
                <tbody>
                  ${(block.rows || []).map((row) => `<tr>${row.map((cell) => `<td>${renderLearningMarkdownInline(cell)}</td>`).join('')}</tr>`).join('')}
                </tbody>
              </table>
            </div>
          `;
        case 'paragraph':
        default:
          return `<p>${renderLearningMarkdownInline(block.text).replace(/\n/g, '<br>')}</p>`;
      }
    })
    .join('');
}

function getLearningCourseCatalog() {
  // Keep the built-in learning catalog local to the component.
  // 将内建学习课程目录保留在组件本地。
  return [
    {
      id: 'english-storytelling',
      category: 'english',
      accent: 'aurora',
      icon: 'EN',
      title: {
        'zh-CN': '英语表达：故事化开口',
        'en-US': 'English Speaking: Story-First Flow',
        'zh-TW': '英語表達：故事化開口',
      },
      subtitle: {
        'zh-CN': '用可复述的表达模板训练英文介绍、观点和复盘。',
        'en-US': 'Train intros, opinions, and recaps with reusable speaking templates.',
        'zh-TW': '用可複述的表達模板訓練英文介紹、觀點與復盤。',
      },
      meta: {
        'zh-CN': '6 节课 · 初中级',
        'en-US': '6 lessons · Beginner to Intermediate',
        'zh-TW': '6 堂課 · 初中階',
      },
      tags: {
        'zh-CN': ['开口', '复述', '表达'],
        'en-US': ['Speaking', 'Retelling', 'Framing'],
        'zh-TW': ['開口', '複述', '表達'],
      },
      markdown: {
        'zh-CN': `# 英语表达：故事化开口

> 目标：把“我知道单词，但说不出来”拆成可练习的步骤。

## 学习路径

- 用 **场景句** 打开话题
- 用 **原因句** 补充观点
- 用 **结果句** 做收尾
- 用 \`3-sentence loop\` 反复训练

## 表达模板

| 场景 | 起手句 | 延展句 |
| --- | --- | --- |
| 自我介绍 | I usually work on... | The part I enjoy most is... |
| 复盘经历 | One thing I learned is... | Next time I would... |
| 观点表达 | I tend to think... | The main reason is... |

## 练习代码块

\`\`\`text
Topic: Describe a skill you are learning.
1. Start with the situation.
2. Explain why it matters.
3. End with one next action.
\`\`\`

---

## 思维导图

\`\`\`mermaid
mindmap
  root((English speaking))
    Opening
      Scene sentence
      Role sentence
    Opinion
      Main idea
      One example
    Closing
      Next action
      Reflection
\`\`\`

## 今日任务

- [x] 跟读 3 轮模板句
- [ ] 用自己的项目经历替换关键词
- [ ] 录一段 30 秒复述音频`,
        'en-US': `# English Speaking: Story-First Flow

> Goal: turn "I know the words, but I cannot speak" into repeatable drills.

## Learning path

- Start with a **scene sentence**
- Add your view with a **reason sentence**
- Close with an **outcome sentence**
- Repeat everything with a \`3-sentence loop\`

## Speaking template

| Scenario | Opening | Expansion |
| --- | --- | --- |
| Intro | I usually work on... | The part I enjoy most is... |
| Reflection | One thing I learned is... | Next time I would... |
| Opinion | I tend to think... | The main reason is... |

## Drill prompt

\`\`\`text
Topic: Describe a skill you are learning.
1. Start with the situation.
2. Explain why it matters.
3. End with one next action.
\`\`\`

---

## Mind map

\`\`\`mermaid
mindmap
  root((English speaking))
    Opening
      Scene sentence
      Role sentence
    Opinion
      Main idea
      One example
    Closing
      Next action
      Reflection
\`\`\`

## Today

- [x] Shadow the template for 3 rounds
- [ ] Replace the keywords with your own project story
- [ ] Record one 30-second recap`,
        'zh-TW': `# 英語表達：故事化開口

> 目標：把「我知道單字，但說不出來」拆成可練習的步驟。

## 學習路徑

- 用 **場景句** 打開話題
- 用 **原因句** 補充觀點
- 用 **結果句** 做收尾
- 用 \`3-sentence loop\` 反覆訓練

## 表達模板

| 場景 | 起手句 | 延展句 |
| --- | --- | --- |
| 自我介紹 | I usually work on... | The part I enjoy most is... |
| 復盤經歷 | One thing I learned is... | Next time I would... |
| 觀點表達 | I tend to think... | The main reason is... |

## 練習代碼塊

\`\`\`text
Topic: Describe a skill you are learning.
1. Start with the situation.
2. Explain why it matters.
3. End with one next action.
\`\`\`

---

## 思維導圖

\`\`\`mermaid
mindmap
  root((English speaking))
    Opening
      Scene sentence
      Role sentence
    Opinion
      Main idea
      One example
    Closing
      Next action
      Reflection
\`\`\`

## 今日任務

- [x] 跟讀 3 輪模板句
- [ ] 用自己的專案經歷替換關鍵詞
- [ ] 錄一段 30 秒複述音訊`,
      },
    },
    {
      id: 'programming-systems',
      category: 'programming',
      accent: 'ember',
      icon: 'DEV',
      title: {
        'zh-CN': '编程实战：把需求拆成系统',
        'en-US': 'Programming: Turning Features into Systems',
        'zh-TW': '程式實戰：把需求拆成系統',
      },
      subtitle: {
        'zh-CN': '从界面、状态、接口到验证，练习完整开发链路。',
        'en-US': 'Practice the full build loop from UI and state to APIs and verification.',
        'zh-TW': '從介面、狀態、介面到驗證，練習完整開發鏈路。',
      },
      meta: {
        'zh-CN': '8 节课 · 进阶',
        'en-US': '8 lessons · Intermediate',
        'zh-TW': '8 堂課 · 進階',
      },
      tags: {
        'zh-CN': ['架构', '状态', '验证'],
        'en-US': ['Architecture', 'State', 'Verification'],
        'zh-TW': ['架構', '狀態', '驗證'],
      },
      markdown: {
        'zh-CN': `# 编程实战：把需求拆成系统

## 四段式拆解

1. 先定义用户界面和关键路径
2. 再定义状态与数据结构
3. 再定义接口与错误处理
4. 最后补构建、测试和回归验证

> 你写的不是“页面”，而是一套可维护的行为系统。

## 最小实现清单

- 页面入口
- 路由状态
- 课程数据模型
- Markdown 渲染器
- 图表渲染兜底

## 示例代码

\`\`\`javascript
function openLearningCourse(courseId) {
  const selected = courses.find((course) => course.id === courseId);
  if (!selected) {
    throw new Error('course not found');
  }
  return {
    ...selected,
    openedAt: new Date().toISOString(),
  };
}
\`\`\`

## 设计表

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| 服务卡片 | 服务状态 | 导航入口 |
| 课程列表 | 分类筛选 | 当前课程 |
| Markdown 渲染器 | 原始正文 | 安全 HTML / Widget |
| Mermaid 渲染器 | \`mermaid\` 代码块 | SVG / 源码兜底 |

## 系统图

\`\`\`mermaid
flowchart LR
  A[Service card] --> B[Course list]
  B --> C[Markdown renderer]
  C --> D[Code block]
  C --> E[Mermaid block]
  E --> F[Diagram output]
\`\`\``,
        'en-US': `# Programming: Turning Features into Systems

## Four-step breakdown

1. Define the UI and the key user path
2. Define state and data structures
3. Define APIs and error handling
4. Finish with build, tests, and regression checks

> You are not shipping a page. You are shipping a maintainable behavior system.

## Minimum implementation list

- Page entry
- Route state
- Course data model
- Markdown renderer
- Diagram fallback

## Example code

\`\`\`javascript
function openLearningCourse(courseId) {
  const selected = courses.find((course) => course.id === courseId);
  if (!selected) {
    throw new Error('course not found');
  }
  return {
    ...selected,
    openedAt: new Date().toISOString(),
  };
}
\`\`\`

## Design table

| Module | Input | Output |
| --- | --- | --- |
| Service card | Service health | Navigation entry |
| Course list | Category filter | Active course |
| Markdown renderer | Raw body | Safe HTML / Widget |
| Mermaid renderer | \`mermaid\` fence | SVG / source fallback |

## System map

\`\`\`mermaid
flowchart LR
  A[Service card] --> B[Course list]
  B --> C[Markdown renderer]
  C --> D[Code block]
  C --> E[Mermaid block]
  E --> F[Diagram output]
\`\`\``,
        'zh-TW': `# 程式實戰：把需求拆成系統

## 四段式拆解

1. 先定義使用者介面和關鍵路徑
2. 再定義狀態與資料結構
3. 再定義介面與錯誤處理
4. 最後補建置、測試與回歸驗證

> 你寫的不是「頁面」，而是一套可維護的行為系統。

## 最小實作清單

- 頁面入口
- 路由狀態
- 課程資料模型
- Markdown 渲染器
- 圖表渲染兜底

## 範例程式碼

\`\`\`javascript
function openLearningCourse(courseId) {
  const selected = courses.find((course) => course.id === courseId);
  if (!selected) {
    throw new Error('course not found');
  }
  return {
    ...selected,
    openedAt: new Date().toISOString(),
  };
}
\`\`\`

## 設計表

| 模組 | 輸入 | 輸出 |
| --- | --- | --- |
| 服務卡片 | 服務狀態 | 導航入口 |
| 課程列表 | 分類篩選 | 目前課程 |
| Markdown 渲染器 | 原始正文 | 安全 HTML / Widget |
| Mermaid 渲染器 | \`mermaid\` 程式碼塊 | SVG / 原始碼兜底 |

## 系統圖

\`\`\`mermaid
flowchart LR
  A[Service card] --> B[Course list]
  B --> C[Markdown renderer]
  C --> D[Code block]
  C --> E[Mermaid block]
  E --> F[Diagram output]
\`\`\``,
      },
    },
    {
      id: 'ai-workflows',
      category: 'ai',
      accent: 'cyan',
      icon: 'AI',
      title: {
        'zh-CN': 'AI 工作流：从提示词到交付',
        'en-US': 'AI Workflows: From Prompt to Delivery',
        'zh-TW': 'AI 工作流：從提示詞到交付',
      },
      subtitle: {
        'zh-CN': '把模型调用、上下文管理和人工校验串成可靠流程。',
        'en-US': 'Connect model calls, context management, and review into a reliable loop.',
        'zh-TW': '把模型呼叫、上下文管理與人工校驗串成可靠流程。',
      },
      meta: {
        'zh-CN': '7 节课 · 中高级',
        'en-US': '7 lessons · Intermediate to Advanced',
        'zh-TW': '7 堂課 · 中高階',
      },
      tags: {
        'zh-CN': ['提示词', '上下文', '校验'],
        'en-US': ['Prompting', 'Context', 'Verification'],
        'zh-TW': ['提示詞', '上下文', '校驗'],
      },
      markdown: {
        'zh-CN': `# AI 工作流：从提示词到交付

## 核心原则

- 给模型清晰的角色、目标和输出格式
- 把不稳定信息放进显式上下文
- 让验证步骤和生成步骤分离

## 输出格式示例

\`\`\`json
{
  "goal": "summarize code changes",
  "constraints": [
    "keep it concise",
    "cite modified files",
    "state verification status"
  ]
}
\`\`\`

## 质量检查

| 检查项 | 说明 |
| --- | --- |
| 来源是否明确 | 输入上下文是否可追溯 |
| 结构是否稳定 | 输出字段是否固定 |
| 结果是否可验证 | 是否有测试、日志或页面回看 |

## 代理流程图

\`\`\`mermaid
mindmap
  root((AI workflow))
    Prompt
      Role
      Goal
      Constraints
    Context
      Files
      Docs
      State
    Verification
      Tests
      Review
      Final answer
\`\`\`

---

## 结论

> 好的 AI 页面不是“能生成内容”，而是“能稳定交付结果”。`,
        'en-US': `# AI Workflows: From Prompt to Delivery

## Core rules

- Give the model a clear role, goal, and output shape
- Move unstable facts into explicit context
- Separate verification from generation

## Output schema example

\`\`\`json
{
  "goal": "summarize code changes",
  "constraints": [
    "keep it concise",
    "cite modified files",
    "state verification status"
  ]
}
\`\`\`

## Quality checks

| Check | Meaning |
| --- | --- |
| Source clarity | Can the input context be traced? |
| Structure stability | Are the output fields fixed? |
| Verifiability | Is there a test, log, or page review? |

## Agent workflow map

\`\`\`mermaid
mindmap
  root((AI workflow))
    Prompt
      Role
      Goal
      Constraints
    Context
      Files
      Docs
      State
    Verification
      Tests
      Review
      Final answer
\`\`\`

---

## Conclusion

> A good AI page is not "able to generate". It is "able to deliver reliably."`,
        'zh-TW': `# AI 工作流：從提示詞到交付

## 核心原則

- 給模型清晰的角色、目標與輸出格式
- 把不穩定資訊放進顯式上下文
- 讓驗證步驟與生成步驟分離

## 輸出格式範例

\`\`\`json
{
  "goal": "summarize code changes",
  "constraints": [
    "keep it concise",
    "cite modified files",
    "state verification status"
  ]
}
\`\`\`

## 品質檢查

| 檢查項 | 說明 |
| --- | --- |
| 來源是否明確 | 輸入上下文是否可追溯 |
| 結構是否穩定 | 輸出欄位是否固定 |
| 結果是否可驗證 | 是否有測試、日誌或頁面回看 |

## 代理流程圖

\`\`\`mermaid
mindmap
  root((AI workflow))
    Prompt
      Role
      Goal
      Constraints
    Context
      Files
      Docs
      State
    Verification
      Tests
      Review
      Final answer
\`\`\`

---

## 結論

> 好的 AI 頁面不是「能生成內容」，而是「能穩定交付結果」。`,
      },
    },
  ];
}

let learningMermaidInitialized = false;

function ensureLearningMermaid() {
  // Initialize Mermaid once so course diagrams can be rendered on demand.
  // 仅初始化一次 Mermaid，便于按需渲染课程图表。
  if (!window.mermaid || learningMermaidInitialized) {
    return;
  }
  window.mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'strict',
    theme: 'dark',
  });
  learningMermaidInitialized = true;
}

async function renderLearningMermaid(rootElement) {
  // Render any pending Mermaid blocks inside the current learning page.
  // 渲染当前学习页中尚未处理的 Mermaid 图表块。
  if (!rootElement || !window.mermaid) {
    return;
  }
  ensureLearningMermaid();
  const nodes = Array.from(
    rootElement.querySelectorAll('.learning-mermaid-graph:not([data-mermaid-rendered="true"])'),
  );
  if (!nodes.length) {
    return;
  }
  try {
    nodes.forEach((node) => {
      node.dataset.mermaidRendered = 'true';
    });
    await window.mermaid.run({ nodes });
  } catch (_error) {
    nodes.forEach((node) => {
      node.classList.add('learning-mermaid-fallback');
      delete node.dataset.mermaidRendered;
    });
  }
}

function parseLearningCourseFileDescriptor(path) {
  // Accept backend lesson files that match `courses/{courseId}.{locale}.md`.
  // 接受匹配 `courses/{courseId}.{locale}.md` 的后端课程文件。
  const normalized = String(path || '').trim();
  if (!normalized.startsWith('courses/') || !normalized.endsWith('.md')) {
    return null;
  }
  const fileName = normalized.slice('courses/'.length);
  const lastDot = fileName.lastIndexOf('.');
  if (lastDot <= 0) {
    return null;
  }
  const localeDot = fileName.lastIndexOf('.', lastDot - 1);
  if (localeDot <= 0) {
    return null;
  }
  const courseId = fileName.slice(0, localeDot);
  const languageCode = fileName.slice(localeDot + 1, lastDot);
  if (!courseId || !languageCode) {
    return null;
  }
  return { courseId, languageCode };
}

function humanizeLearningCourseId(courseId) {
  // Turn one slug-like course id into a readable fallback title.
  // 将 slug 风格课程 ID 转换为可读兜底标题。
  return String(courseId || '')
    .split(/[-_]+/)
    .filter(Boolean)
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join(' ') || String(courseId || '');
}

function buildBackendLearningCatalog(items) {
  // Convert backend markdown summaries into learning course cards for the legacy web frontend.
  // 将后端 Markdown 摘要转换为 Legacy Web 前端可用的课程卡片。
  const grouped = new Map();
  for (const item of Array.isArray(items) ? items : []) {
    const descriptor = parseLearningCourseFileDescriptor(item?.path);
    if (!descriptor) {
      continue;
    }
    if (!grouped.has(descriptor.courseId)) {
      grouped.set(descriptor.courseId, []);
    }
    grouped.get(descriptor.courseId).push({
      path: String(item.path || ''),
      updatedAt: item.updated_at || item.updatedAt || '',
      languageCode: descriptor.languageCode,
    });
  }

  const accents = ['aurora', 'ember', 'cyan'];
  return Array.from(grouped.entries())
    .sort((left, right) => left[0].localeCompare(right[0]))
    .map(([courseId, entries], index) => {
      const localeCodes = Array.from(new Set(entries.map((entry) => entry.languageCode))).sort();
      const latestUpdatedAt = entries
        .map((entry) => new Date(entry.updatedAt))
        .filter((value) => !Number.isNaN(value.getTime()))
        .sort((left, right) => right.getTime() - left.getTime())[0];
      const updateLabel = latestUpdatedAt
        ? `${latestUpdatedAt.getFullYear()}-${String(latestUpdatedAt.getMonth() + 1).padStart(2, '0')}-${String(latestUpdatedAt.getDate()).padStart(2, '0')}`
        : 'Backend';
      const fallbackTitle = humanizeLearningCourseId(courseId);
      return {
        id: courseId,
        category: 'all',
        accent: accents[index % accents.length],
        icon: courseId.length >= 3 ? courseId.slice(0, 3).toUpperCase() : courseId.toUpperCase(),
        title: {
          'zh-CN': fallbackTitle,
          'en-US': fallbackTitle,
          'zh-TW': fallbackTitle,
        },
        subtitle: {
          'zh-CN': '来自 learning-service 的动态课程文件，可随内容仓库持续扩展。',
          'en-US': 'A backend-driven lesson discovered from learning-service and ready to grow with the content repository.',
          'zh-TW': '來自 learning-service 的動態課程檔案，可隨內容倉庫持續擴展。',
        },
        meta: {
          'zh-CN': `${localeCodes.length} 个语言版本 · 更新 ${updateLabel}`,
          'en-US': `${localeCodes.length} locale variants · Updated ${updateLabel}`,
          'zh-TW': `${localeCodes.length} 個語言版本 · 更新 ${updateLabel}`,
        },
        tags: {
          'zh-CN': ['后端同步', ...localeCodes],
          'en-US': ['Backend sync', ...localeCodes],
          'zh-TW': ['後端同步', ...localeCodes],
        },
        markdown: {},
      };
    });
}

window.LearningService = {
  props: {
    app: {
      type: Object,
      required: true,
    },
    adminWorkspaceOnly: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    const catalog = getLearningCourseCatalog();
    return {
      activeCategory: 'all',
      activeCourseId: catalog[0]?.id || '',
      catalogItems: [],
      backendCourses: [],
      catalogLoading: false,
      catalogError: '',
      markdownCache: {},
      markdownLoading: false,
      markdownError: '',
      adminConsoleMode: false,
      editorMode: false,
      markdownSaving: false,
      adminOverviewFilter: 'all',
      saveStatus: '',
      markdownDraft: '',
      markdownDraftBaseline: '',
      createLessonOpen: false,
      createLessonError: '',
      createLessonDraft: {
        courseId: '',
        locale: 'zh-CN',
        content: '# New Lesson\n\nWrite your course content here.',
      },
      codeExecutionStates: {},
      clipboardMessage: '',
    };
  },
  computed: {
    categoryOptions() {
      return [
        {
          key: 'all',
          label: localizedLearningText(this.app, {
            'zh-CN': '全部课程',
            'en-US': 'All courses',
            'zh-TW': '全部課程',
          }),
        },
        {
          key: 'english',
          label: localizedLearningText(this.app, {
            'zh-CN': '英语',
            'en-US': 'English',
            'zh-TW': '英語',
          }),
        },
        {
          key: 'programming',
          label: localizedLearningText(this.app, {
            'zh-CN': '编程',
            'en-US': 'Programming',
            'zh-TW': '程式',
          }),
        },
        {
          key: 'ai',
          label: localizedLearningText(this.app, {
            'zh-CN': 'AI',
            'en-US': 'AI',
            'zh-TW': 'AI',
          }),
        },
      ];
    },
    courses() {
      const merged = new Map();
      for (const course of getLearningCourseCatalog()) {
        merged.set(course.id, course);
      }
      for (const course of this.backendCourses) {
        merged.set(course.id, course);
      }
      return Array.from(merged.values());
    },
    visibleCourses() {
      if (this.activeCategory === 'all') {
        return this.courses;
      }
      return this.courses.filter((course) => course.category === this.activeCategory);
    },
    activeCourse() {
      return this.courses.find((course) => course.id === this.activeCourseId) || this.visibleCourses[0] || this.courses[0] || null;
    },
    featureChips() {
      return [
        localizedLearningText(this.app, {
          'zh-CN': 'Markdown 正文',
          'en-US': 'Markdown lessons',
          'zh-TW': 'Markdown 正文',
        }),
        localizedLearningText(this.app, {
          'zh-CN': '代码块',
          'en-US': 'Code fences',
          'zh-TW': '程式碼塊',
        }),
        localizedLearningText(this.app, {
          'zh-CN': '表格',
          'en-US': 'Tables',
          'zh-TW': '表格',
        }),
        localizedLearningText(this.app, {
          'zh-CN': 'Mermaid 思维导图',
          'en-US': 'Mermaid mind maps',
          'zh-TW': 'Mermaid 思維導圖',
        }),
      ];
    },
    activeCourseMarkdown() {
      if (!this.activeCourse) {
        return '';
      }
      const localePath = this.courseMarkdownPath(this.activeCourse, this.app?.locale);
      const fallbackPath = this.courseMarkdownPath(this.activeCourse, 'zh-CN');
      return this.markdownCache[localePath]?.content
        || this.markdownCache[fallbackPath]?.content
        || this.courseFallbackMarkdown(this.activeCourse, this.app?.locale);
    },
    hasUnsavedEditorChanges() {
      return this.markdownDraft !== this.markdownDraftBaseline;
    },
    activeCourseFiles() {
      if (!this.activeCourse) {
        return [];
      }
      const prefix = `courses/${this.activeCourse.id}.`;
      return this.catalogItems
        .filter((item) => String(item?.path || '').startsWith(prefix))
        .sort((left, right) => String(left.path || '').localeCompare(String(right.path || '')));
    },
    activeCourseStatusCounts() {
      return this.activeCourseFiles.reduce((summary, item) => {
        const status = String(item?.status || 'published').trim().toLowerCase();
        if (status === 'draft') {
          summary.draft += 1;
        } else if (status === 'archived') {
          summary.archived += 1;
        } else {
          summary.published += 1;
        }
        return summary;
      }, {
        draft: 0,
        published: 0,
        archived: 0,
      });
    },
    adminCourseSummaries() {
      const summaries = new Map(
        this.courses.map((course) => [course.id, {
          courseId: course.id,
          title: this.courseText(course, 'title') || course.id,
          totalFiles: 0,
          draftFiles: 0,
          publishedFiles: 0,
          archivedFiles: 0,
        }]),
      );
      this.catalogItems.forEach((item) => {
        const match = String(item?.path || '').match(/^courses\/(.+)\.([^.]+)\.md$/);
        if (!match) {
          return;
        }
        const courseId = match[1];
        const summary = summaries.get(courseId) || {
          courseId,
          title: courseId,
          totalFiles: 0,
          draftFiles: 0,
          publishedFiles: 0,
          archivedFiles: 0,
        };
        summary.totalFiles += 1;
        const status = String(item?.status || 'published').trim().toLowerCase();
        if (status === 'draft') {
          summary.draftFiles += 1;
        } else if (status === 'archived') {
          summary.archivedFiles += 1;
        } else {
          summary.publishedFiles += 1;
        }
        summaries.set(courseId, summary);
      });
      return Array.from(summaries.values()).sort((left, right) => {
        const leftPriority = left.draftFiles > 0 && left.publishedFiles === 0
          ? 0
          : left.draftFiles > 0 && left.publishedFiles > 0
          ? 1
          : left.publishedFiles > 0
          ? 2
          : left.archivedFiles > 0
          ? 3
          : 4;
        const rightPriority = right.draftFiles > 0 && right.publishedFiles === 0
          ? 0
          : right.draftFiles > 0 && right.publishedFiles > 0
          ? 1
          : right.publishedFiles > 0
          ? 2
          : right.archivedFiles > 0
          ? 3
          : 4;
        if (leftPriority !== rightPriority) {
          return leftPriority - rightPriority;
        }
        if (left.draftFiles !== right.draftFiles) {
          return right.draftFiles - left.draftFiles;
        }
        if (left.totalFiles !== right.totalFiles) {
          return right.totalFiles - left.totalFiles;
        }
        return String(left.courseId).localeCompare(String(right.courseId));
      });
    },
    filteredAdminCourseSummaries() {
      switch (this.adminOverviewFilter) {
        case 'pending':
          return this.adminCourseSummaries.filter((summary) => summary.draftFiles > 0);
        case 'draft':
          return this.adminCourseSummaries.filter((summary) => summary.draftFiles > 0);
        case 'published':
          return this.adminCourseSummaries.filter((summary) => summary.publishedFiles > 0);
        case 'archived':
          return this.adminCourseSummaries.filter((summary) => summary.archivedFiles > 0);
        default:
          return this.adminCourseSummaries;
      }
    },
    nextPendingCourseId() {
      return this.adminCourseSummaries.find((summary) => summary.draftFiles > 0)?.courseId || '';
    },
    isAdmin() {
      // Resolve whether the current signed-in account can manage lesson publishing.
      // 判断当前登录账号是否具备课程上架管理权限。
      return String(this.app?.user?.level || '').toLowerCase() === 'admin';
    },
  },
  watch: {
    activeCourseId() {
      this.editorMode = false;
      this.adminConsoleMode = this.adminWorkspaceOnly;
      this.saveStatus = '';
      this.syncEditorWithActiveCourse(true);
      this.loadActiveCourseMarkdown();
      this.scheduleMermaidRender();
    },
    activeCategory() {
      if (!this.visibleCourses.find((course) => course.id === this.activeCourseId)) {
        this.activeCourseId = this.visibleCourses[0]?.id || this.courses[0]?.id || '';
      }
      this.editorMode = false;
      this.adminConsoleMode = this.adminWorkspaceOnly;
      this.saveStatus = '';
      this.syncEditorWithActiveCourse(true);
      this.loadActiveCourseMarkdown();
      this.scheduleMermaidRender();
    },
    'app.locale'() {
      this.editorMode = false;
      this.adminConsoleMode = this.adminWorkspaceOnly;
      this.saveStatus = '';
      this.syncEditorWithActiveCourse(true);
      this.loadActiveCourseMarkdown();
      this.scheduleMermaidRender();
    },
    adminWorkspaceOnly(value) {
      if (value) {
        this.adminConsoleMode = true;
      }
    },
  },
  mounted() {
    this.adminConsoleMode = this.adminWorkspaceOnly;
    this.loadCourseCatalog();
    this.loadActiveCourseMarkdown();
    this.scheduleMermaidRender();
    this.$el.addEventListener('click', this.handleLearningBodyClick);
  },
  beforeUnmount() {
    if (this._clipboardTimer) {
      window.clearTimeout(this._clipboardTimer);
    }
    if (this.$el) {
      this.$el.removeEventListener('click', this.handleLearningBodyClick);
    }
  },
  updated() {
    this.scheduleMermaidRender();
  },
  methods: {
    learningText(values) {
      // Resolve one localized UI label for the current course view.
      // 为当前课程视图解析一条本地化文案。
      return localizedLearningText(this.app, values);
    },
    setCategory(categoryKey) {
      // Switch the course category and keep the selected course aligned.
      // 切换课程分类，并保持当前课程选择同步。
      this.activeCategory = categoryKey;
    },
    openCourse(courseId) {
      // Open one course in the preview panel.
      // 在预览面板中打开一门课程。
      this.activeCourseId = courseId;
    },
    openServices() {
      // Return to the service navigator from the learning detail page.
      // 从学习详情页返回服务导航。
      this.app.view = 'services';
    },
    courseText(course, field) {
      return localizedLearningText(this.app, course?.[field]);
    },
    courseTags(course) {
      const tags = localizedLearningText(this.app, course?.tags);
      return Array.isArray(tags) ? tags : [];
    },
    courseFallbackMarkdown(course, locale) {
      // Keep the existing built-in markdown as a resilient fallback.
      // 保留现有内建 Markdown 作为兜底内容。
      return localizedLearningText(this.app, course?.markdown) || course?.markdown?.[locale] || course?.markdown?.['zh-CN'] || '';
    },
    courseMarkdownPath(course, locale) {
      // Map one course and locale to the backend markdown-file resource path.
      // 将课程与语言映射到后端 Markdown 文件资源路径。
      const normalizedLocale = locale || 'zh-CN';
      return `courses/${course.id}.${normalizedLocale}.md`;
    },
    activeCourseMarkdownPath() {
      // Resolve the current course markdown path for the active locale.
      // 解析当前语言下当前课程对应的 Markdown 路径。
      return this.courseMarkdownPath(this.activeCourse, this.app?.locale);
    },
    normalizeCourseIdInput(value) {
      // Normalize one course id input into a safe slug that matches backend markdown path rules.
      // 将课程 ID 输入规范化为匹配后端 Markdown 路径规则的安全 slug。
      return String(value || '')
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9_-]+/g, '-')
        .replace(/-{2,}/g, '-')
        .replace(/^-+|-+$/g, '');
    },
    syncEditorWithActiveCourse(force = false) {
      // Align the editor draft with the active course unless the user is editing unsaved content.
      // 让编辑器草稿与当前课程保持一致，但避免覆盖用户未保存的编辑内容。
      if (!force && this.editorMode && this.hasUnsavedEditorChanges) {
        return;
      }
      const nextContent = this.activeCourseMarkdown;
      this.markdownDraft = nextContent;
      this.markdownDraftBaseline = nextContent;
    },
    async fetchCourseMarkdown(relativePath) {
      // Load one markdown document from the learning service and unwrap the API envelope.
      // 从学习服务加载单个 Markdown 文档，并解包 API 包装。
      const encodedPath = String(relativePath || '')
        .split('/')
        .filter(Boolean)
        .map((segment) => encodeURIComponent(segment))
        .join('/');
      const response = await fetch(`${this.app.learningApiBase}/markdown-files/${encodedPath}`, {
        headers: {
          Authorization: `Bearer ${this.app.token}`,
        },
      });
      if (!response.ok) {
        throw new Error(`markdown request failed: ${response.status}`);
      }
      return this.app.readApiPayload(response);
    },
    async listCourseMarkdownFiles() {
      // Load the backend markdown file list so the legacy frontend can discover additional lessons.
      // 读取后端 Markdown 文件列表，让 Legacy 前端也能发现新增课程。
      const response = await fetch(`${this.app.learningApiBase}/markdown-files`, {
        headers: {
          Authorization: `Bearer ${this.app.token}`,
        },
      });
      const payload = await this.app.readApiPayload(response);
      if (!response.ok) {
        throw new Error(payload.error || payload.message || `markdown list failed: ${response.status}`);
      }
      return Array.isArray(payload.items) ? payload.items : [];
    },
    async saveCourseMarkdown(relativePath, content) {
      // Persist one course markdown file back to learning-service.
      // 将单个课程 Markdown 文件保存回 learning-service。
      const encodedPath = String(relativePath || '')
        .split('/')
        .filter(Boolean)
        .map((segment) => encodeURIComponent(segment))
        .join('/');
      const response = await fetch(`${this.app.learningApiBase}/markdown-files/${encodedPath}`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${this.app.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content,
        }),
      });
      const payload = await this.app.readApiPayload(response);
      if (!response.ok) {
        throw new Error(payload.error || payload.message || `markdown save failed: ${response.status}`);
      }
      return payload;
    },
    async deleteCourseMarkdown(relativePath) {
      // Delete one lesson markdown file through the administrator-only learning endpoint.
      // 通过仅管理员可用的学习接口删除单个课程 Markdown 文件。
      const encodedPath = String(relativePath || '')
        .split('/')
        .filter(Boolean)
        .map((segment) => encodeURIComponent(segment))
        .join('/');
      const response = await fetch(`${this.app.learningApiBase}/markdown-files/${encodedPath}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${this.app.token}`,
        },
      });
      const payload = await this.app.readApiPayload(response);
      if (!response.ok) {
        throw new Error(payload.error || payload.message || `markdown delete failed: ${response.status}`);
      }
      return payload;
    },
    async updateCourseMarkdownStatus(relativePath, status) {
      // Update one lesson file publishing status through the administrator-only learning endpoint.
      // 通过仅管理员可用的学习接口更新单个课程文件的发布状态。
      const encodedPath = String(relativePath || '')
        .split('/')
        .filter(Boolean)
        .map((segment) => encodeURIComponent(segment))
        .join('/');
      const response = await fetch(`${this.app.learningApiBase}/markdown-file-status/${encodedPath}`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${this.app.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          status,
        }),
      });
      const payload = await this.app.readApiPayload(response);
      if (!response.ok) {
        throw new Error(payload.error || payload.message || `markdown status update failed: ${response.status}`);
      }
      return payload;
    },
    normalizeRunnableLanguage(language) {
      // Normalize one markdown fence info string into a backend execution language token.
      // 将 Markdown 代码块语言标识规范化为后端执行语言标记。
      const normalized = String(language || '').trim().toLowerCase();
      switch (normalized) {
        case 'go':
        case 'golang':
          return 'go';
        case 'js':
        case 'javascript':
        case 'node':
          return 'javascript';
        case 'py':
        case 'python':
          return 'python';
        default:
          return '';
      }
    },
    codeLanguageLabel(language) {
      // Resolve one concise runtime label for UI actions.
      // 为界面动作解析简短的运行时标签。
      switch (this.normalizeRunnableLanguage(language)) {
        case 'javascript':
          return 'JS';
        case 'python':
          return 'Python';
        case 'go':
        default:
          return 'Go';
      }
    },
    async executeCodeSnippet(language, source) {
      // Send one runnable snippet to the backend executor and unwrap the API payload.
      // 将一段可运行代码发送到后端执行器，并解包接口响应。
      const normalizedLanguage = this.normalizeRunnableLanguage(language);
      if (!normalizedLanguage) {
        throw new Error(`unsupported language: ${language}`);
      }
      const response = await fetch(`${this.app.learningApiBase}/code-executions/${encodeURIComponent(normalizedLanguage)}`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.app.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          source,
        }),
      });
      const payload = await this.app.readApiPayload(response);
      if (!response.ok) {
        throw new Error(payload.error || payload.message || `code execution failed: ${response.status}`);
      }
      return payload;
    },
    codeExecutionKey(course, blockIndex) {
      // Build a stable key for one rendered runnable code block.
      // 为单个可运行代码块构建稳定键值。
      return `${course?.id || 'course'}:${this.app?.locale || 'zh-CN'}:${blockIndex}`;
    },
    executionStateForBlock(course, blockIndex) {
      // Look up the current execution state for one rendered code block.
      // 读取单个渲染代码块的当前执行状态。
      return this.codeExecutionStates[this.codeExecutionKey(course, blockIndex)] || null;
    },
    clearExecutionState(course, blockIndex) {
      // Remove one rendered code block execution state from the local cache.
      // 清除单个渲染代码块的执行状态缓存。
      const key = this.codeExecutionKey(course, blockIndex);
      const nextState = {
        ...this.codeExecutionStates,
      };
      delete nextState[key];
      this.codeExecutionStates = nextState;
    },
    updateExecutionState(course, blockIndex, patch) {
      // Update one code block execution state reactively.
      // 以响应式方式更新单个代码块的执行状态。
      const key = this.codeExecutionKey(course, blockIndex);
      this.codeExecutionStates = {
        ...this.codeExecutionStates,
        [key]: {
          ...(this.codeExecutionStates[key] || {}),
          ...patch,
        },
      };
    },
    async copyCodeBlock(blockIndex) {
      // Copy the selected runnable Go block into the clipboard and surface a lightweight confirmation.
      // 将选中的 Go 代码块复制到剪贴板，并显示轻量确认文案。
      if (!this.activeCourse) {
        return;
      }
      const blocks = parseLearningMarkdownBlocks(this.activeCourseMarkdown);
      const block = blocks[blockIndex];
      if (!block || block.type !== 'code') {
        return;
      }
      try {
        await copyLearningText(block.text || '');
        this.clipboardMessage = this.learningText({
          'zh-CN': '代码已复制到剪贴板。',
          'en-US': 'Code copied to clipboard.',
          'zh-TW': '程式碼已複製到剪貼簿。',
        });
      } catch (_error) {
        this.clipboardMessage = this.learningText({
          'zh-CN': '复制失败，请手动复制。',
          'en-US': 'Copy failed. Please copy it manually.',
          'zh-TW': '複製失敗，請手動複製。',
        });
      }
      window.clearTimeout?.(this._clipboardTimer);
      this._clipboardTimer = window.setTimeout(() => {
        this.clipboardMessage = '';
      }, 2200);
    },
    async runCodeBlock(blockIndex) {
      // Execute the selected runnable fence and keep its output inline beneath the code block.
      // 执行所选可运行代码块，并将输出内嵌展示在代码块下方。
      if (!this.activeCourse) {
        return;
      }
      const blocks = parseLearningMarkdownBlocks(this.activeCourseMarkdown);
      const block = blocks[blockIndex];
      const normalizedLanguage = this.normalizeRunnableLanguage(block?.info || '');
      if (!block || block.type !== 'code' || !normalizedLanguage) {
        return;
      }

      this.updateExecutionState(this.activeCourse, blockIndex, {
        running: true,
        error: '',
        stdout: '',
        stderr: '',
        meta: this.learningText({
          'zh-CN': '正在运行...',
          'en-US': 'Running...',
          'zh-TW': '執行中...',
        }),
      });

      try {
        const payload = await this.executeCodeSnippet(normalizedLanguage, block.text || '');
        const timedOut = Boolean(payload.timed_out);
        const durationMs = Number(payload.duration_ms || 0);
        const exitCode = Number(payload.exit_code ?? 0);
        this.updateExecutionState(this.activeCourse, blockIndex, {
          running: false,
          error: '',
          stdout: String(payload.stdout || ''),
          stderr: String(payload.stderr || ''),
          meta: timedOut
            ? this.learningText({
              'zh-CN': `已超时 · ${durationMs} ms`,
              'en-US': `Timed out · ${durationMs} ms`,
              'zh-TW': `已逾時 · ${durationMs} ms`,
            })
            : this.learningText({
              'zh-CN': `退出码 ${exitCode} · ${durationMs} ms`,
              'en-US': `Exit ${exitCode} · ${durationMs} ms`,
              'zh-TW': `退出碼 ${exitCode} · ${durationMs} ms`,
            }),
        });
      } catch (error) {
        this.updateExecutionState(this.activeCourse, blockIndex, {
          running: false,
          error: String(error?.message || error || ''),
          stdout: '',
          stderr: '',
          meta: this.learningText({
            'zh-CN': '请求失败',
            'en-US': 'Request failed',
            'zh-TW': '請求失敗',
          }),
        });
      }
    },
    async loadActiveCourseMarkdown() {
      // Prefer backend markdown content, then gracefully fall back to the local built-in course body.
      // 优先读取后端 Markdown 内容，失败时再平稳回退到本地内建课程正文。
      if (!this.activeCourse || !this.app?.token || !this.app?.learningApiBase) {
        return;
      }
      const locale = this.app?.locale || 'zh-CN';
      const candidatePaths = [
        this.courseMarkdownPath(this.activeCourse, locale),
      ];
      if (locale !== 'zh-CN') {
        candidatePaths.push(this.courseMarkdownPath(this.activeCourse, 'zh-CN'));
      }
      const nextCache = {};
      let loaded = false;
      this.markdownLoading = true;
      this.markdownError = '';
      for (const path of candidatePaths) {
        if (this.markdownCache[path]?.content) {
          loaded = true;
          continue;
        }
        try {
          const payload = await this.fetchCourseMarkdown(path);
          nextCache[path] = {
            content: String(payload.content || ''),
            updatedAt: payload.updated_at || '',
            status: String(payload.status || 'published'),
          };
          loaded = true;
        } catch (_error) {
          // Ignore missing locale variants and keep the fallback path chain going.
          // 忽略缺失的语言变体，并继续尝试后续兜底路径。
        }
      }
      if (Object.keys(nextCache).length) {
        this.markdownCache = {
          ...this.markdownCache,
          ...nextCache,
        };
      }
      if (!loaded && this.app.isServiceOnline('learning')) {
        this.markdownError = localizedLearningText(this.app, {
          'zh-CN': '后端课程文件暂未返回，当前显示内建示例内容。',
          'en-US': 'The backend lesson file is not available yet, so the built-in sample is shown.',
          'zh-TW': '後端課程檔案暫未返回，目前顯示內建示例內容。',
        });
      }
      this.markdownLoading = false;
      this.syncEditorWithActiveCourse();
    },
    async loadCourseCatalog() {
      // Discover backend lessons so the legacy frontend stays aligned with the learning-service content repository.
      // 发现后端课程，让 Legacy 前端与 learning-service 内容仓库保持同步。
      if (!this.app?.token || !this.app?.learningApiBase) {
        return;
      }
      this.catalogLoading = true;
      this.catalogError = '';
      try {
        const items = await this.listCourseMarkdownFiles();
        this.catalogItems = Array.isArray(items) ? items : [];
        this.backendCourses = buildBackendLearningCatalog(items);
      } catch (_error) {
        this.catalogError = localizedLearningText(this.app, {
          'zh-CN': '后端课程索引暂不可用，当前继续显示内建课程目录。',
          'en-US': 'The backend lesson index is unavailable, so the built-in catalog is still shown.',
          'zh-TW': '後端課程索引暫不可用，目前繼續顯示內建課程目錄。',
        });
      }
      this.catalogLoading = false;
    },
    toggleEditorMode() {
      // Switch between rendered preview and Markdown source editing for the active lesson.
      // 在当前课程的渲染预览与 Markdown 源码编辑之间切换。
      if (!this.isAdmin) {
        return;
      }
      if (!this.editorMode) {
        this.syncEditorWithActiveCourse(true);
      }
      this.editorMode = !this.editorMode;
      this.saveStatus = '';
    },
    toggleAdminConsoleMode() {
      // Switch between learner preview and administrator workspace.
      // 在学习者预览与管理员工作区之间切换。
      if (!this.isAdmin) {
        return;
      }
      if (this.adminWorkspaceOnly) {
        return;
      }
      this.adminConsoleMode = !this.adminConsoleMode;
      if (!this.adminConsoleMode) {
        this.editorMode = false;
      } else {
        this.syncEditorWithActiveCourse(true);
      }
      this.saveStatus = '';
    },
    toggleCreateLessonForm() {
      // Toggle the lesson-creation form so users can add a new backend markdown file from the UI.
      // 切换课程创建表单，让用户可以直接从界面新增后端 Markdown 文件。
      if (!this.isAdmin) {
        return;
      }
      this.createLessonOpen = !this.createLessonOpen;
      this.createLessonError = '';
      if (this.createLessonOpen) {
        this.createLessonDraft = {
          courseId: '',
          locale: ['zh-CN', 'en-US', 'zh-TW'].includes(this.app?.locale) ? this.app.locale : 'zh-CN',
          content: '# New Lesson\n\nWrite your course content here.',
        };
      }
    },
    resetMarkdownDraft() {
      // Reset the draft back to the latest loaded markdown snapshot.
      // 将草稿重置为最近一次已加载的 Markdown 快照。
      if (!this.isAdmin) {
        return;
      }
      this.markdownDraft = this.activeCourseMarkdown;
      this.markdownDraftBaseline = this.activeCourseMarkdown;
      this.saveStatus = localizedLearningText(this.app, {
        'zh-CN': '已重置为当前已加载内容。',
        'en-US': 'Reset to the currently loaded lesson content.',
        'zh-TW': '已重設為目前已載入內容。',
      });
    },
    async reloadActiveCourseMarkdown() {
      // Drop the active course cache so the next load re-reads markdown from the backend.
      // 丢弃当前课程缓存，让下一次加载重新从后端读取 Markdown。
      if (!this.activeCourse) {
        return;
      }
      const activePath = this.activeCourseMarkdownPath();
      const fallbackPath = this.courseMarkdownPath(this.activeCourse, 'zh-CN');
      if (activePath) {
        delete this.markdownCache[activePath];
      }
      if (fallbackPath && fallbackPath !== activePath) {
        delete this.markdownCache[fallbackPath];
      }
      this.markdownCache = {
        ...this.markdownCache,
      };
      this.saveStatus = '';
      await this.loadActiveCourseMarkdown();
    },
    async saveActiveCourseMarkdown() {
      // Save the active editor draft and refresh the preview cache in place.
      // 保存当前编辑草稿，并就地刷新预览缓存。
      if (!this.activeCourse || !this.isAdmin) {
        return;
      }
      const relativePath = this.activeCourseMarkdownPath();
      this.markdownSaving = true;
      this.saveStatus = '';
      try {
        const payload = await this.saveCourseMarkdown(relativePath, this.markdownDraft);
        this.markdownCache = {
          ...this.markdownCache,
          [relativePath]: {
            content: String(payload.content || ''),
            updatedAt: payload.updated_at || '',
            status: String(payload.status || 'published'),
          },
        };
        this.markdownDraft = String(payload.content || '');
        this.markdownDraftBaseline = this.markdownDraft;
        this.markdownError = '';
        this.saveStatus = localizedLearningText(this.app, {
          'zh-CN': '课程内容已保存到 learning-service。',
          'en-US': 'Lesson content saved to learning-service.',
          'zh-TW': '課程內容已儲存到 learning-service。',
        });
        await this.loadCourseCatalog();
      } catch (error) {
        this.saveStatus = String(error?.message || error || '');
      }
      this.markdownSaving = false;
    },
    async deleteActiveLessonFile() {
      // Delete the active locale lesson file so administrators can take it offline from the console.
      // 删除当前语言课程文件，让管理员可以直接在后台下架。
      if (!this.activeCourse || !this.isAdmin) {
        return;
      }
      const confirmed = window.confirm(this.learningText({
        'zh-CN': '确认删除当前语言版本的课程文件吗？',
        'en-US': 'Delete the current locale lesson file?',
        'zh-TW': '確認刪除目前語言版本的課程檔案嗎？',
      }));
      if (!confirmed) {
        return;
      }
      const relativePath = this.activeCourseMarkdownPath();
      await this.deleteSpecificLessonFile(relativePath);
    },
    async deleteSpecificLessonFile(relativePath) {
      // Delete one specific lesson file from the admin console file list.
      // 从管理员后台文件列表中删除指定课程文件。
      if (!relativePath || !this.isAdmin) {
        return;
      }
      this.markdownSaving = true;
      this.saveStatus = '';
      try {
        await this.deleteCourseMarkdown(relativePath);
        const nextCache = {
          ...this.markdownCache,
        };
        delete nextCache[relativePath];
        this.markdownCache = nextCache;
        this.editorMode = false;
        this.saveStatus = localizedLearningText(this.app, {
          'zh-CN': '课程文件已删除。',
          'en-US': 'The lesson file was deleted.',
          'zh-TW': '課程檔案已刪除。',
        });
        await this.loadCourseCatalog();
        await this.loadActiveCourseMarkdown();
      } catch (error) {
        this.saveStatus = String(error?.message || error || '');
      }
      this.markdownSaving = false;
    },
    lessonStatusText(status) {
      // Resolve one localized lesson status label for the admin file list.
      // 为管理员文件列表解析本地化课程状态标签。
      switch (String(status || 'published').trim().toLowerCase()) {
        case 'draft':
          return this.learningText({
            'zh-CN': '草稿',
            'en-US': 'Draft',
            'zh-TW': '草稿',
          });
        case 'archived':
          return this.learningText({
            'zh-CN': '已归档',
            'en-US': 'Archived',
            'zh-TW': '已歸檔',
          });
        default:
          return this.learningText({
            'zh-CN': '已发布',
            'en-US': 'Published',
            'zh-TW': '已發布',
          });
      }
    },
    lessonStatusClass(status) {
      // Map one lesson status to the matching badge skin class.
      // 将课程状态映射到对应的徽章样式类。
      switch (String(status || 'published').trim().toLowerCase()) {
        case 'draft':
          return 'learning-status-badge--draft';
        case 'archived':
          return 'learning-status-badge--archived';
        default:
          return 'learning-status-badge--published';
      }
    },
    async updateSpecificLessonStatus(relativePath, status) {
      // Publish or archive one specific lesson file from the admin console file list.
      // 在管理员后台文件列表中发布或归档指定课程文件。
      if (!relativePath || !this.isAdmin) {
        return;
      }
      this.markdownSaving = true;
      this.saveStatus = '';
      try {
        await this.updateCourseMarkdownStatus(relativePath, status);
        const cachedDocument = this.markdownCache[relativePath];
        if (cachedDocument) {
          this.markdownCache = {
            ...this.markdownCache,
            [relativePath]: {
              ...cachedDocument,
              status,
            },
          };
        }
        this.saveStatus = localizedLearningText(this.app, status === 'published' ? {
          'zh-CN': '课程文件已发布，学员端现可见。',
          'en-US': 'The lesson file is now published and visible to learners.',
          'zh-TW': '課程檔案已發布，學員端現在可見。',
        } : {
          'zh-CN': '课程文件已归档，学员端现已隐藏。',
          'en-US': 'The lesson file is now archived and hidden from learners.',
          'zh-TW': '課程檔案已歸檔，學員端現在已隱藏。',
        });
        await this.loadCourseCatalog();
        if (relativePath === this.activeCourseMarkdownPath()) {
          await this.loadActiveCourseMarkdown();
        }
      } catch (error) {
        this.saveStatus = String(error?.message || error || '');
      }
      this.markdownSaving = false;
    },
    async createLessonFile() {
      // Create a brand-new lesson file and switch the view to that course after it is saved.
      // 创建全新的课程文件，并在保存后自动切换到该课程。
      if (!this.isAdmin) {
        return;
      }
      const normalizedCourseId = this.normalizeCourseIdInput(this.createLessonDraft.courseId);
      if (!normalizedCourseId) {
        this.createLessonError = localizedLearningText(this.app, {
          'zh-CN': '请先填写有效的课程 ID。',
          'en-US': 'Enter a valid course ID first.',
          'zh-TW': '請先填寫有效的課程 ID。',
        });
        return;
      }
      this.markdownSaving = true;
      this.createLessonError = '';
      const locale = this.createLessonDraft.locale || 'zh-CN';
      const relativePath = `courses/${normalizedCourseId}.${locale}.md`;
      try {
        const payload = await this.saveCourseMarkdown(
          relativePath,
          this.createLessonDraft.content,
        );
        this.markdownCache = {
          ...this.markdownCache,
          [relativePath]: {
            content: String(payload.content || ''),
            updatedAt: payload.updated_at || '',
            status: String(payload.status || 'draft'),
          },
        };
        this.createLessonOpen = false;
        this.saveStatus = localizedLearningText(this.app, {
          'zh-CN': '新课程文件已创建为草稿并保存。',
          'en-US': 'The new lesson file was created as a draft and saved.',
          'zh-TW': '新課程檔案已建立為草稿並儲存。',
        });
        await this.loadCourseCatalog();
        this.activeCourseId = normalizedCourseId;
      } catch (error) {
        this.createLessonError = String(error?.message || error || '');
      }
      this.markdownSaving = false;
    },
    renderCourseMarkdown(course) {
      // Render the selected course body into safe HTML.
      // 将当前课程正文渲染为安全 HTML。
      return renderLearningMarkdownContent(this.activeCourseMarkdown, {
        isRunnableCode: (block) => {
          return Boolean(this.normalizeRunnableLanguage(block?.info || ''));
        },
        executionState: (_block, blockIndex) => this.executionStateForBlock(course, blockIndex),
        labels: {
          run: this.learningText({
            'zh-CN': '运行代码',
            'en-US': 'Run code',
            'zh-TW': '執行程式碼',
          }),
          running: this.learningText({
            'zh-CN': '运行中...',
            'en-US': 'Running...',
            'zh-TW': '執行中...',
          }),
          copy: this.learningText({
            'zh-CN': '复制代码',
            'en-US': 'Copy code',
            'zh-TW': '複製程式碼',
          }),
          reset: this.learningText({
            'zh-CN': '重置输出',
            'en-US': 'Reset output',
            'zh-TW': '重設輸出',
          }),
          output: this.learningText({
            'zh-CN': '输出结果',
            'en-US': 'Output',
            'zh-TW': '輸出結果',
          }),
          stderr: this.learningText({
            'zh-CN': '错误输出',
            'en-US': 'stderr',
            'zh-TW': '錯誤輸出',
          }),
          error: this.learningText({
            'zh-CN': '请求错误',
            'en-US': 'Request error',
            'zh-TW': '請求錯誤',
          }),
          empty: this.learningText({
            'zh-CN': '本次运行没有标准输出。',
            'en-US': 'This run produced no stdout output.',
            'zh-TW': '本次執行沒有標準輸出。',
          }),
        },
      });
    },
    handleLearningBodyClick(event) {
      // Delegate clicks from runnable code blocks rendered through v-html.
      // 代理处理通过 v-html 渲染出的可运行代码块点击事件。
      const button = event?.target?.closest?.('[data-learning-run="code"]');
      if (button) {
        const blockIndex = Number(button.getAttribute('data-learning-block-index'));
        if (Number.isFinite(blockIndex) && blockIndex >= 0) {
          this.runCodeBlock(blockIndex);
        }
        return;
      }
      const copyButton = event?.target?.closest?.('[data-learning-copy-code="true"]');
      if (copyButton) {
        const blockIndex = Number(copyButton.getAttribute('data-learning-block-index'));
        if (Number.isFinite(blockIndex) && blockIndex >= 0) {
          this.copyCodeBlock(blockIndex);
        }
        return;
      }
      const resetButton = event?.target?.closest?.('[data-learning-reset-output="true"]');
      if (!resetButton) {
        return;
      }
      const blockIndex = Number(resetButton.getAttribute('data-learning-block-index'));
      if (!Number.isFinite(blockIndex) || blockIndex < 0 || !this.activeCourse) {
        return;
      }
      this.clearExecutionState(this.activeCourse, blockIndex);
    },
    scheduleMermaidRender() {
      // Wait for the DOM patch, then render newly mounted Mermaid nodes.
      // 等待 DOM 更新后再渲染新挂载的 Mermaid 节点。
      this.$nextTick(() => {
        window.requestAnimationFrame(() => {
          renderLearningMermaid(this.$el);
        });
      });
    },
  },
  template: `
    <section class="panel services-page learning-page">
      <div class="space-page-hero services-page-hero learning-hero">
        <div class="learning-hero-copy">
          <div class="space-shell-kicker">{{ app.t('learning.kicker') }}</div>
          <div class="space-page-title">{{ adminWorkspaceOnly ? app.t('learningAdmin.title') : app.t('learning.title') }}</div>
          <div class="space-page-sub">{{ adminWorkspaceOnly ? app.t('learningAdmin.sub') : app.t('learning.sub') }}</div>
          <div class="learning-feature-row">
            <span v-for="chip in featureChips" :key="chip" class="learning-feature-chip">{{ chip }}</span>
          </div>
        </div>
        <div class="learning-hero-actions">
          <bilingual-action-button
            variant="tonal"
            compact
            type="button"
            :primary-label="app.t('learning.backToServices')"
            :secondary-label="app.peerLocaleText('learning.backToServices')"
            @click="openServices"
          ></bilingual-action-button>
        </div>
      </div>

      <div class="learning-layout">
        <aside class="learning-sidebar">
          <div class="learning-sidebar-head">
            <div class="service-card-title">{{ app.t('learning.catalogTitle') }}</div>
            <div class="service-card-sub">{{ app.t('learning.catalogSub') }}</div>
          </div>
          <p v-if="catalogLoading || catalogError" class="learning-status-note">
            {{ catalogLoading ? learningText({
              'zh-CN': '正在同步后端课程目录...',
              'en-US': 'Syncing backend lesson catalog...',
              'zh-TW': '正在同步後端課程目錄...',
            }) : catalogError }}
          </p>
          <div class="learning-category-row">
            <button
              v-for="category in categoryOptions"
              :key="category.key"
              type="button"
              class="learning-category-chip"
              :class="{ active: activeCategory === category.key }"
              @click="setCategory(category.key)"
            >
              {{ category.label }}
            </button>
          </div>
          <div class="learning-course-list">
            <button
              v-for="course in visibleCourses"
              :key="course.id"
              type="button"
              class="learning-course-card"
              :class="['learning-course-card--' + course.accent, { active: activeCourse && activeCourse.id === course.id }]"
              @click="openCourse(course.id)"
            >
              <div class="learning-course-card-head">
                <span class="learning-course-icon">{{ course.icon }}</span>
                <span class="learning-course-meta">{{ courseText(course, 'meta') }}</span>
              </div>
              <div class="learning-course-title">{{ courseText(course, 'title') }}</div>
              <div class="learning-course-sub">{{ courseText(course, 'subtitle') }}</div>
              <div class="learning-course-tags">
                <span v-for="tag in courseTags(course)" :key="course.id + '-' + tag" class="service-chip">{{ tag }}</span>
              </div>
            </button>
          </div>
        </aside>

        <article v-if="activeCourse" class="learning-detail panel accent">
          <div class="learning-detail-head">
            <div>
              <div class="space-shell-kicker">{{ app.t('learning.currentCourse') }}</div>
              <h2>{{ courseText(activeCourse, 'title') }}</h2>
              <p>{{ courseText(activeCourse, 'subtitle') }}</p>
            </div>
            <div class="learning-course-meta learning-course-meta--detail">{{ courseText(activeCourse, 'meta') }}</div>
          </div>
          <div class="learning-course-tags learning-course-tags--detail">
            <span v-for="tag in courseTags(activeCourse)" :key="activeCourse.id + '-detail-' + tag" class="service-chip">{{ tag }}</span>
          </div>
          <div v-if="isAdmin" class="learning-editor-toolbar">
            <bilingual-action-button
              v-if="!adminWorkspaceOnly"
              :variant="adminConsoleMode ? 'primary' : 'tonal'"
              compact
              type="button"
              :primary-label="adminConsoleMode ? learningText({
                'zh-CN': '返回课程预览',
                'en-US': 'Back to lesson preview',
                'zh-TW': '返回課程預覽',
              }) : learningText({
                'zh-CN': '管理员后台',
                'en-US': 'Admin console',
                'zh-TW': '管理員後台',
              })"
              secondary-label=""
              @click="toggleAdminConsoleMode"
            ></bilingual-action-button>
            <template v-if="adminConsoleMode">
            <bilingual-action-button
              :variant="editorMode ? 'primary' : 'tonal'"
              compact
              type="button"
              :primary-label="editorMode ? learningText({
                'zh-CN': '切换到预览',
                'en-US': 'Back to preview',
                'zh-TW': '切換到預覽',
              }) : learningText({
                'zh-CN': '编辑 Markdown',
                'en-US': 'Edit markdown',
                'zh-TW': '編輯 Markdown',
              })"
              secondary-label=""
              @click="toggleEditorMode"
            ></bilingual-action-button>
            <bilingual-action-button
              variant="tonal"
              compact
              type="button"
              :primary-label="learningText({
                'zh-CN': createLessonOpen ? '收起新建' : '新建课程',
                'en-US': createLessonOpen ? 'Hide new lesson' : 'New lesson',
                'zh-TW': createLessonOpen ? '收起新建' : '新建課程',
              })"
              secondary-label=""
              @click="toggleCreateLessonForm"
            ></bilingual-action-button>
            <bilingual-action-button
              variant="ghost"
              compact
              type="button"
              :primary-label="learningText({
                'zh-CN': '重新加载',
                'en-US': 'Reload',
                'zh-TW': '重新載入',
              })"
              secondary-label=""
              @click="reloadActiveCourseMarkdown"
            ></bilingual-action-button>
            <bilingual-action-button
              variant="ghost"
              compact
              type="button"
              :primary-label="learningText({
                'zh-CN': '删除当前版本',
                'en-US': 'Delete locale file',
                'zh-TW': '刪除目前版本',
              })"
              secondary-label=""
              :disabled="markdownSaving"
              @click="deleteActiveLessonFile"
            ></bilingual-action-button>
            <template v-if="editorMode">
              <bilingual-action-button
                variant="ghost"
                compact
                type="button"
                :primary-label="learningText({
                  'zh-CN': '重置草稿',
                  'en-US': 'Reset draft',
                  'zh-TW': '重設草稿',
                })"
                secondary-label=""
                :disabled="markdownSaving"
                @click="resetMarkdownDraft"
              ></bilingual-action-button>
              <bilingual-action-button
                variant="primary"
                compact
                type="button"
                :primary-label="markdownSaving ? learningText({
                  'zh-CN': '保存中...',
                  'en-US': 'Saving...',
                  'zh-TW': '儲存中...',
                }) : learningText({
                  'zh-CN': '保存到服务',
                  'en-US': 'Save to service',
                  'zh-TW': '儲存到服務',
                })"
                secondary-label=""
                :disabled="markdownSaving || !hasUnsavedEditorChanges"
                @click="saveActiveCourseMarkdown"
              ></bilingual-action-button>
            </template>
            </template>
          </div>
          <p v-else class="learning-status-note">
            {{ learningText({
              'zh-CN': '课程上架与内容维护需管理员权限。',
              'en-US': 'Publishing and course maintenance require administrator access.',
              'zh-TW': '課程上架與內容維護需管理員權限。',
            }) }}
          </p>
          <p v-if="markdownLoading" class="learning-status-note">Loading course markdown...</p>
          <p v-else-if="markdownError" class="learning-status-note">{{ markdownError }}</p>
          <p v-if="saveStatus" class="learning-status-note">{{ saveStatus }}</p>
          <p v-if="clipboardMessage" class="learning-status-note">{{ clipboardMessage }}</p>
          <div v-if="isAdmin && adminConsoleMode && activeCourseFiles.length" class="learning-admin-files">
            <div class="learning-admin-files-head">
              <div class="service-card-title">{{ learningText({
                'zh-CN': '课程版本文件',
                'en-US': 'Lesson files',
                'zh-TW': '課程版本檔案',
              }) }}</div>
              <div class="service-card-sub">{{ learningText({
                'zh-CN': '管理员可直接查看当前课程已存在的语言版本文件，并逐个发布、归档或删除。',
                'en-US': 'Administrators can inspect every locale file for this lesson and publish, archive, or delete them one by one.',
                'zh-TW': '管理員可直接查看目前課程已存在的語言版本檔案，並逐一發布、歸檔或刪除。',
              }) }}</div>
            </div>
            <div class="learning-admin-file-list">
              <div v-for="item in activeCourseFiles" :key="item.path" class="learning-admin-file-row">
                <div class="learning-admin-file-copy">
                  <div class="learning-admin-file-path">{{ item.path }}</div>
                  <div class="learning-admin-file-meta">
                    {{ item.size || 0 }}B · {{ item.updated_at || item.updatedAt || '--' }}
                    <span v-if="item.path === activeCourseMarkdownPath()"> · {{ learningText({
                      'zh-CN': '当前界面版本',
                      'en-US': 'Active in this view',
                      'zh-TW': '目前介面版本',
                    }) }}</span>
                  </div>
                  <div :class="['learning-status-badge', lessonStatusClass(item.status)]">
                    {{ lessonStatusText(item.status) }}
                  </div>
                </div>
                <div class="learning-admin-file-actions">
                  <bilingual-action-button
                    variant="tonal"
                    compact
                    type="button"
                    :primary-label="learningText({
                      'zh-CN': '发布',
                      'en-US': 'Publish',
                      'zh-TW': '發布',
                    })"
                    secondary-label=""
                    :disabled="markdownSaving || String(item.status || 'published').toLowerCase() === 'published'"
                    @click="updateSpecificLessonStatus(item.path, 'published')"
                  ></bilingual-action-button>
                  <bilingual-action-button
                    variant="ghost"
                    compact
                    type="button"
                    :primary-label="learningText({
                      'zh-CN': '归档',
                      'en-US': 'Archive',
                      'zh-TW': '歸檔',
                    })"
                    secondary-label=""
                    :disabled="markdownSaving || String(item.status || '').toLowerCase() === 'archived'"
                    @click="updateSpecificLessonStatus(item.path, 'archived')"
                  ></bilingual-action-button>
                </div>
                <div class="learning-admin-file-actions">
                  <bilingual-action-button
                    variant="ghost"
                    compact
                    type="button"
                    :primary-label="learningText({
                      'zh-CN': '删除',
                      'en-US': 'Delete',
                      'zh-TW': '刪除',
                    })"
                    secondary-label=""
                    :disabled="markdownSaving"
                    @click="deleteSpecificLessonFile(item.path)"
                  ></bilingual-action-button>
                </div>
              </div>
            </div>
          </div>
          <div v-if="adminConsoleMode && createLessonOpen" class="learning-editor-shell">
            <p class="learning-editor-help">
              {{ learningText({
                'zh-CN': '创建后会在 learning-service 中生成 courses/{courseId}.{locale}.md 文件。',
                'en-US': 'This creates a courses/{courseId}.{locale}.md draft file inside learning-service.',
                'zh-TW': '建立後會在 learning-service 中生成 courses/{courseId}.{locale}.md 草稿檔案。',
              }) }}
            </p>
            <div class="learning-create-grid">
              <label class="identity-field">
                <span class="identity-label">
                  <span class="identity-label-main">{{ learningText({
                    'zh-CN': '课程 ID',
                    'en-US': 'Course ID',
                    'zh-TW': '課程 ID',
                  }) }}</span>
                </span>
                <input v-model="createLessonDraft.courseId" type="text" placeholder="my-new-course" />
                <div class="form-hint">{{ learningText({
                  'zh-CN': '仅支持小写字母、数字、-、_。',
                  'en-US': 'Use lowercase letters, numbers, hyphens, and underscores.',
                  'zh-TW': '僅支援小寫字母、數字、-、_。',
                }) }}</div>
              </label>
              <label class="identity-field">
                <span class="identity-label">
                  <span class="identity-label-main">{{ learningText({
                    'zh-CN': '语言版本',
                    'en-US': 'Locale',
                    'zh-TW': '語言版本',
                  }) }}</span>
                </span>
                <select v-model="createLessonDraft.locale">
                  <option value="zh-CN">zh-CN</option>
                  <option value="en-US">en-US</option>
                  <option value="zh-TW">zh-TW</option>
                </select>
              </label>
            </div>
            <textarea
              class="learning-editor-textarea"
              v-model="createLessonDraft.content"
              :placeholder="learningText({
                'zh-CN': '支持标题、表格、代码块和 Mermaid 语法。',
                'en-US': 'Supports headings, tables, code fences, and Mermaid syntax.',
                'zh-TW': '支援標題、表格、程式碼塊與 Mermaid 語法。',
              })"
            ></textarea>
            <p v-if="createLessonError" class="learning-status-note">{{ createLessonError }}</p>
            <div class="learning-editor-toolbar">
              <bilingual-action-button
                variant="ghost"
                compact
                type="button"
                :primary-label="learningText({
                  'zh-CN': '取消',
                  'en-US': 'Cancel',
                  'zh-TW': '取消',
                })"
                secondary-label=""
                :disabled="markdownSaving"
                @click="toggleCreateLessonForm"
              ></bilingual-action-button>
              <bilingual-action-button
                variant="primary"
                compact
                type="button"
                :primary-label="markdownSaving ? learningText({
                  'zh-CN': '创建中...',
                  'en-US': 'Creating...',
                  'zh-TW': '建立中...',
                }) : learningText({
                  'zh-CN': '创建课程文件',
                  'en-US': 'Create lesson file',
                  'zh-TW': '建立課程檔案',
                })"
                secondary-label=""
                :disabled="markdownSaving"
                @click="createLessonFile"
              ></bilingual-action-button>
            </div>
          </div>
          <div v-else-if="adminConsoleMode && editorMode" class="learning-editor-shell">
            <p class="learning-editor-help">
              {{ learningText({
                'zh-CN': '在这里直接编辑课程 Markdown，保存后会写回 learning-service。',
                'en-US': 'Edit the lesson markdown here and save it back to learning-service.',
                'zh-TW': '在這裡直接編輯課程 Markdown，儲存後會寫回 learning-service。',
              }) }}
            </p>
            <textarea
              class="learning-editor-textarea"
              v-model="markdownDraft"
              :placeholder="learningText({
                'zh-CN': '支持标题、表格、代码块和 Mermaid 语法。',
                'en-US': 'Supports headings, tables, code fences, and Mermaid syntax.',
                'zh-TW': '支援標題、表格、程式碼塊與 Mermaid 語法。',
              })"
            ></textarea>
          </div>
          <div v-else-if="adminConsoleMode" class="learning-admin-files">
            <div class="learning-admin-files-head">
              <div class="service-card-title">{{ learningText({
                'zh-CN': '管理员后台工作区',
                'en-US': 'Administrator workspace',
                'zh-TW': '管理員後台工作區',
              }) }}</div>
              <div class="service-card-sub">{{ learningText({
                'zh-CN': '这里会集中放置课程创建、版本管理、上架与下架动作。当前版本已支持新建、编辑、发布、归档、删除和文件清单管理。',
                'en-US': 'This workspace centralizes lesson creation, version management, and publishing actions. The current build already supports create, edit, publish, archive, delete, and file-list management.',
                'zh-TW': '這裡會集中放置課程建立、版本管理、上架與下架動作。目前版本已支援新建、編輯、發布、歸檔、刪除與檔案清單管理。',
              }) }}</div>
            </div>
            <div v-if="nextPendingCourseId" class="learning-admin-overview-filters">
              <bilingual-action-button
                variant="primary"
                compact
                type="button"
                :primary-label="learningText({
                  'zh-CN': '打开待处理课程',
                  'en-US': 'Open next pending lesson',
                  'zh-TW': '打開待處理課程',
                })"
                secondary-label=""
                @click="openCourse(nextPendingCourseId)"
              ></bilingual-action-button>
            </div>
            <div class="learning-admin-file-meta">
              {{ learningText({
                'zh-CN': '当前课程文件数',
                'en-US': 'Current lesson file count',
                'zh-TW': '目前課程檔案數',
              }) }}: {{ activeCourseFiles.length }}
            </div>
            <div class="learning-admin-file-meta">
              {{ learningText({
                'zh-CN': '草稿',
                'en-US': 'Draft',
                'zh-TW': '草稿',
              }) }} {{ activeCourseStatusCounts.draft }} ·
              {{ learningText({
                'zh-CN': '已发布',
                'en-US': 'Published',
                'zh-TW': '已發布',
              }) }} {{ activeCourseStatusCounts.published }} ·
              {{ learningText({
                'zh-CN': '已归档',
                'en-US': 'Archived',
                'zh-TW': '已歸檔',
              }) }} {{ activeCourseStatusCounts.archived }}
            </div>
            <div class="learning-admin-overview">
              <div class="service-card-title">{{ learningText({
                'zh-CN': '课程总览',
                'en-US': 'Course overview',
                'zh-TW': '課程總覽',
              }) }}</div>
              <div class="service-card-sub">{{ learningText({
                'zh-CN': '先看全局课程状态，再切到具体课程继续维护语言版本和上架动作。',
                'en-US': 'Scan global course status first, then jump into a specific lesson to manage locale variants and publishing.',
                'zh-TW': '先看全域課程狀態，再切到具體課程繼續維護語言版本與上架動作。',
              }) }}</div>
              <div class="learning-admin-overview-filters">
                <bilingual-action-button
                  v-for="filter in [
                    { key: 'all', label: learningText({ 'zh-CN': '全部', 'en-US': 'All', 'zh-TW': '全部' }) },
                    { key: 'pending', label: learningText({ 'zh-CN': '待处理', 'en-US': 'Pending', 'zh-TW': '待處理' }) },
                    { key: 'draft', label: learningText({ 'zh-CN': '草稿', 'en-US': 'Draft', 'zh-TW': '草稿' }) },
                    { key: 'published', label: learningText({ 'zh-CN': '已发布', 'en-US': 'Published', 'zh-TW': '已發布' }) },
                    { key: 'archived', label: learningText({ 'zh-CN': '已归档', 'en-US': 'Archived', 'zh-TW': '已歸檔' }) },
                  ]"
                  :key="filter.key"
                  :variant="adminOverviewFilter === filter.key ? 'primary' : 'tonal'"
                  compact
                  type="button"
                  :primary-label="filter.label"
                  secondary-label=""
                  @click="adminOverviewFilter = filter.key"
                ></bilingual-action-button>
              </div>
              <div class="learning-admin-overview-list">
                <p v-if="!filteredAdminCourseSummaries.length" class="learning-status-note">
                  {{ learningText({
                    'zh-CN': '当前筛选条件下暂无课程。',
                    'en-US': 'No lessons match the current filter.',
                    'zh-TW': '目前篩選條件下沒有課程。',
                  }) }}
                </p>
                <div v-for="summary in filteredAdminCourseSummaries" :key="summary.courseId" class="learning-admin-overview-row">
                  <div class="learning-admin-overview-copy">
                    <div class="learning-admin-file-path">{{ summary.title }}</div>
                    <div class="learning-admin-file-meta">{{ summary.courseId }}</div>
                    <div class="learning-admin-overview-chips">
                      <span v-if="summary.draftFiles > 0 && summary.publishedFiles === 0" class="service-chip">{{ learningText({
                        'zh-CN': '待上架',
                        'en-US': 'Needs publish',
                        'zh-TW': '待上架',
                      }) }}</span>
                      <span v-if="summary.draftFiles > 0 && summary.publishedFiles > 0" class="service-chip">{{ learningText({
                        'zh-CN': '待更新',
                        'en-US': 'Needs update',
                        'zh-TW': '待更新',
                      }) }}</span>
                      <span class="service-chip">{{ learningText({
                        'zh-CN': '文件',
                        'en-US': 'Files',
                        'zh-TW': '檔案',
                      }) }} {{ summary.totalFiles }}</span>
                      <span class="service-chip">{{ learningText({
                        'zh-CN': '草稿',
                        'en-US': 'Draft',
                        'zh-TW': '草稿',
                      }) }} {{ summary.draftFiles }}</span>
                      <span class="service-chip">{{ learningText({
                        'zh-CN': '已发布',
                        'en-US': 'Published',
                        'zh-TW': '已發布',
                      }) }} {{ summary.publishedFiles }}</span>
                      <span class="service-chip">{{ learningText({
                        'zh-CN': '已归档',
                        'en-US': 'Archived',
                        'zh-TW': '已歸檔',
                      }) }} {{ summary.archivedFiles }}</span>
                    </div>
                  </div>
                  <bilingual-action-button
                    :variant="summary.courseId === activeCourseId ? 'primary' : 'tonal'"
                    compact
                    type="button"
                    :primary-label="summary.courseId === activeCourseId ? learningText({
                      'zh-CN': '当前课程',
                      'en-US': 'Current lesson',
                      'zh-TW': '目前課程',
                    }) : learningText({
                      'zh-CN': '打开课程',
                      'en-US': 'Open lesson',
                      'zh-TW': '打開課程',
                    })"
                    secondary-label=""
                    @click="openCourse(summary.courseId)"
                  ></bilingual-action-button>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="post-content--markdown learning-markdown-body" v-html="renderCourseMarkdown(activeCourse)"></div>
        </article>
      </div>
    </section>
  `,
};
