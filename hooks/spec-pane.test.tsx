import { expect, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

const GIT_DIR = '/repo/.git'
const SPEC = `${GIT_DIR}/refine/reject-big-uploads.md`

const SAVED = `---
state: in progress
---

# Reject uploads over the size limit

## Goal

Uploads over 10 MB fail fast.

## Current behaviour

## Acceptance criteria

- [ ] An 11 MB upload is rejected with 413

## Out of scope

## Constraints

- Public contract change: no
- Data migration: yes

## Sources

- https://example.com/upload-limits

## Open questions

- 3 · Size limit: should the limit be configurable?

## Interview

### Round 1

| Question | What I took from your reply |
| -------- | --------------------------- |
| 1 · Goal | Fail fast                   |
`

const PANE = {
  plugin: 'purpleclay-skills',
  component: 'Pane',
  requestId: 'refine-spec',
  props: {
    title: 'Spec',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 40 },
    view: {},
  },
} as const

const engine = (on: On) => {
  const files = new Map<string, string>()
  // Each save gets a later modification time, as a real file system gives it.
  const mtimes = new Map<string, number>()
  let clock = 0
  const save = (path: string, content: string) => {
    files.set(path, content)
    mtimes.set(path, ++clock)
  }
  const panes = { opened: 0, closed: 0 }
  on('process.run', () => ({
    value: { exitCode: 0, stdout: `${GIT_DIR}\n`, stderr: '',
      isStdoutTruncated: false,
      isStderrTruncated: false,
    },
  }))
  on('fs.read', (_, e) => ({ value: files.get(e.path) ?? '' }))
  on('fs.exists', (_, e) => ({ value: files.has(e.path) }))
  on('fs.list', (_, e) => {
    const dir = e.path.endsWith('/') ? e.path : `${e.path}/`
    const value = [...files]
      .filter(([path]) => path.startsWith(dir) && !path.slice(dir.length).includes('/'))
      .map(([path, content]) => ({
        name: path.slice(dir.length),
        kind: 'file' as const,
        size: content.length,
        mtimeMs: mtimes.get(path) ?? 0,
        isLink: false,
      }))

    return { value }
  })
  on('ui.open', () => {
    panes.opened++
    return { value: { isPlaced: true } }
  })
  on('ui.close', () => {
    panes.closed++
    return { value: undefined }
  })
  on('tool.call', (_, e) => {
    if (e.tool === 'Write') save(e.file_path, e.content)
    if (e.tool === 'Bash' && e.command.startsWith('rm ')) {
      files.delete(e.command.slice(3))
      mtimes.delete(e.command.slice(3))
    }
    // A shell save, as /refine often writes the spec: cat > <path> <<'EOF' … EOF
    const shellSave =
      e.tool === 'Bash' ? /^cat > (\S+) <<'EOF'\n([\s\S]*)EOF$/.exec(e.command) : null
    if (shellSave !== null) save(shellSave[1] ?? '', shellSave[2] ?? '')
    return { result: {} }
  })

  return panes
}

const drawn = async ($: Engine) => {
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  const texts = await ui.findAll({ type: 'Text' })
  await ui.unmount()

  return texts.map(node => node.text).join('\n')
}

test('a saved spec opens the pane with its ticket sections only', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })

  expect(panes.opened).toBe(1)
  const text = await drawn($)
  expect(text).toContain('Reject uploads over the size limit')
  expect(text).toContain('Acceptance criteria')
  expect(text).toContain('Constraints')
  expect(text).toContain('https://example.com/upload-limits')
  expect(text).not.toContain('state: in progress')
  expect(text).not.toContain('Open questions')
  expect(text).not.toContain('Interview')
  expect(text).not.toContain('configurable')
})

test('each save shows the spec as last saved', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({
    tool: 'Write',
    file_path: SPEC,
    content: SAVED.replace('10 MB', '20 MB'),
  })

  expect(await drawn($)).toContain('20 MB')
})

const catTo = (path: string, content: string) => `cat > ${path} <<'EOF'\n${content}EOF`

test('a spec saved through the shell opens the pane', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Bash', command: catTo(SPEC, SAVED) })

  expect(panes.opened).toBe(1)
  expect(await drawn($)).toContain('Reject uploads over the size limit')
})

test('a spec updated through the shell shows as last saved', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({ tool: 'Bash', command: catTo(SPEC, SAVED.replace('10 MB', '20 MB')) })

  expect(await drawn($)).toContain('20 MB')
})

test('shell commands that change no spec leave the pane as it is', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Bash', command: 'git status' })
  await $.tool.call({ tool: 'Bash', command: catTo('/repo/notes.md', SAVED) })
  expect(panes.opened).toBe(0)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({ tool: 'Bash', command: `cat ${SPEC}` })
  expect(panes.opened).toBe(1)
})

test('files that are not specs leave the pane shut', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Write', file_path: '/repo/README.md', content: SAVED })
  await $.tool.call({
    tool: 'Write',
    file_path: `${GIT_DIR}/refine/reject-big-uploads.tickets.draft/1.md`,
    content: SAVED,
  })

  expect(panes.opened).toBe(0)
})

test('the pane stays open while the spec exists and closes once it is deleted', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({ tool: 'Bash', command: 'gh issue create' })
  expect(panes.closed).toBe(0)

  await $.tool.call({ tool: 'Bash', command: `rm ${SPEC}` })
  expect(panes.closed).toBe(1)
})

test('the pane draws each part of the spec in Claude Code theme colours', async ($, on) => {
  engine(on)
  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    const colour = async (text: RegExp) =>
      (await ui.find({ type: 'Text', text }))?.props.color

    expect(await colour(/^Reject uploads over the size limit$/)).toBe('claude')
    expect(await colour(/^Goal$/)).toBe('suggestion')
    expect(await colour(/^Not settled yet$/)).toBe('inactive')
    expect(await colour(/^☐ $/)).toBe('subtle')
    expect(await colour(/^An 11 MB upload is rejected with 413$/)).toBe('text')
    expect(await colour(/^yes$/)).toBe('warning')
    expect(await colour(/^no$/)).toBe('subtle')
    expect(await ui.findAll({ type: 'Text', text: /^Not settled yet$/ })).toHaveLength(2)
    await ui.unmount()
  }
})

const row = (
  component: 'ToolUse' | 'ToolResult',
  id: string,
  isExpanded = false,
  isErrored = false,
) =>
  ({
    plugin: 'purpleclay-skills',
    component,
    requestId: id,
    props:
      component === 'ToolUse'
        ? { tool_use_id: id, tool: 'Write', input: {}, isRunning: false, isErrored,
            isInterrupted: false, isExpanded }
        : { tool_use_id: id, tool: 'Write', output: {}, isErrored, isExpanded },
  }) as const

const drawsItsOwn = async (
  $: Engine,
  component: 'ToolUse' | 'ToolResult',
  id: string,
  isExpanded = false,
  isErrored = false,
) => {
  const ui = await $.ui.mount({ ...row(component, id, isExpanded, isErrored), surface: 'terminal' })
  const tree = JSON.stringify(await ui.drawn())
  await ui.unmount()

  // Claude Code's own row, drawn in full, is an engine node in the tree.
  return tree.includes('"type":"engine"')
}

const rowText = async ($: Engine, component: 'ToolUse' | 'ToolResult', id: string, isExpanded = false) => {
  const ui = await $.ui.mount({ ...row(component, id, isExpanded), surface: 'terminal' })
  const texts = await ui.findAll({ type: 'Text' })
  await ui.unmount()

  return texts.map(node => node.text).join('\n')
}

test('each save of a spec draws as one dim line naming its round, with no diff', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED, tool_use_id: 'w1' })
  await $.tool.call({
    tool: 'Bash',
    command: catTo(SPEC, `${SAVED}\n### Round 2\n`),
    tool_use_id: 'b1',
  })
  await $.tool.call({
    tool: 'Write',
    file_path: SPEC,
    content: SAVED.replace(/^---[\s\S]*?---\n\n/, '').replace(/\n## Open questions[\s\S]*/, '\n'),
    tool_use_id: 'w2',
  })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...row('ToolUse', 'w1'), surface })
    const line = await ui.find({ type: 'Text', text: /^Saved spec · round 1$/ })
    expect(line?.props.color).toBe('inactive')
    await ui.unmount()
  }
  expect(await rowText($, 'ToolUse', 'b1')).toBe('Saved spec · round 2')
  expect(await rowText($, 'ToolUse', 'w2')).toBe('Saved spec · ready to publish')
  expect(await drawsItsOwn($, 'ToolResult', 'w1')).toBe(false)
})

test('the full transcript view draws a save in full', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED, tool_use_id: 'w1' })

  expect(await drawsItsOwn($, 'ToolUse', 'w1', true)).toBe(true)
  expect(await drawsItsOwn($, 'ToolResult', 'w1', true)).toBe(true)
})

test('tool calls that save no spec draw as they do today', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED, tool_use_id: 'w1' })
  await $.tool.call({ tool: 'Bash', command: `cat ${SPEC}`, tool_use_id: 'b1' })
  await $.tool.call({
    tool: 'Write',
    file_path: `${GIT_DIR}/refine/reject-big-uploads.tickets.draft/1.md`,
    content: SAVED,
    tool_use_id: 'w2',
  })
  await $.tool.call({ tool: 'Write', file_path: '/repo/README.md', content: SAVED, tool_use_id: 'w3' })

  for (const id of ['b1', 'w2', 'w3']) {
    expect(await drawsItsOwn($, 'ToolUse', id)).toBe(true)
    expect(await drawsItsOwn($, 'ToolResult', id)).toBe(true)
  }
})

test('a save whose call failed draws in full, so its error shows', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Bash', command: catTo(SPEC, SAVED), tool_use_id: 'b1' })

  expect(await drawsItsOwn($, 'ToolUse', 'b1', false, true)).toBe(true)
  expect(await drawsItsOwn($, 'ToolResult', 'b1', false, true)).toBe(true)
})
