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

window.LearningService = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  data() {
    const catalog = getLearningCourseCatalog();
    return {
      activeCategory: 'all',
      activeCourseId: catalog[0]?.id || '',
      markdownCache: {},
      markdownLoading: false,
      markdownError: '',
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
      return getLearningCourseCatalog();
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
  },
  watch: {
    activeCourseId() {
      this.loadActiveCourseMarkdown();
      this.scheduleMermaidRender();
    },
    activeCategory() {
      if (!this.visibleCourses.find((course) => course.id === this.activeCourseId)) {
        this.activeCourseId = this.visibleCourses[0]?.id || this.courses[0]?.id || '';
      }
      this.loadActiveCourseMarkdown();
      this.scheduleMermaidRender();
    },
    'app.locale'() {
      this.loadActiveCourseMarkdown();
      this.scheduleMermaidRender();
    },
  },
  mounted() {
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
          <div class="space-page-title">{{ app.t('learning.title') }}</div>
          <div class="space-page-sub">{{ app.t('learning.sub') }}</div>
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
          <p v-if="markdownLoading" class="learning-status-note">Loading course markdown...</p>
          <p v-else-if="markdownError" class="learning-status-note">{{ markdownError }}</p>
          <p v-if="clipboardMessage" class="learning-status-note">{{ clipboardMessage }}</p>
          <div class="post-content--markdown learning-markdown-body" v-html="renderCourseMarkdown(activeCourse)"></div>
        </article>
      </div>
    </section>
  `,
};
